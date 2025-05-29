#!/usr/bin/env python3
# includes updated logic and file sorting, MetaData, etc

import cv2
import csv
import sys
import time
from PyQt5.QtWidgets import QApplication, QWidget, QLabel, QLineEdit, QPushButton, QFileDialog, QCheckBox, QVBoxLayout
from PyQt5.QtCore import QThread
from PyQt5.QtWidgets import QProgressBar
from PyQt5.QtCore import pyqtSignal
from PyQt5.QtWidgets import QMessageBox
from PyQt5.QtWidgets import QScrollArea
import numpy as np
import argparse
import os
# os.environ.pop("QT_QPA_PLATFORM_PLUGIN_PATH") # FINALLY FIXED 'xcb' plugin error, only works on Scatha
# need to comment out above line of code for macOS
import re
import datetime
import time
from datetime import datetime

class Worker(QThread):
    progress_signal = pyqtSignal(int)

    def __init__(self, callable, *args, **kwargs):
        super().__init__()
        self.callable = callable
        self.args = args
        self.kwargs = kwargs

    def run(self):
        self.callable(*self.args, **self.kwargs)

class ActigraphyProcessorApp(QWidget):
    def __init__(self, actigraphy_processor):
        super().__init__()
        self.actigraphy_processor = actigraphy_processor
        self.output_directory = None
        self.processing_settings_for_metadata = {}
        # can edit three default settings for buttons
        self.settings_most_movement = {'global_threshold': '15', 'percentage_threshold': '25', 'min_size_threshold': '120', 'dilation_kernel': '4'}
        self.settings_medium_movement = {'global_threshold': '30', 'percentage_threshold': '35', 'min_size_threshold': '160', 'dilation_kernel': '3'}
        self.settings_only_large_movement = {'global_threshold': '40', 'percentage_threshold': '50', 'min_size_threshold': '200', 'dilation_kernel': '2'}
        self.init_ui()

    def init_ui(self):
        self.scroll_area = QScrollArea()  # Create a new QScrollArea
        self.scroll_area.setWidgetResizable(True)
        layout = QVBoxLayout()
        # creating buttons for the GUI layout
        self.video_file_label = QLabel("Video File:")
        self.video_file_edit = QLineEdit()
        self.video_file_button = QPushButton("Browse Files")
        self.video_file_button.clicked.connect(self.browse_video_file)

        self.video_folder_label = QLabel("Video Folder:")
        self.video_folder_edit = QLineEdit()
        self.video_folder_button = QPushButton("Browse Folders")
        self.video_folder_button.clicked.connect(self.browse_video_folder)

        self.min_size_threshold_label = QLabel("Minimum Size Threshold:")
        self.min_size_threshold_edit = QLineEdit("0")

        self.global_threshold_label = QLabel("Global Threshold:")
        self.global_threshold_edit = QLineEdit("0")

        self.percentage_threshold_label = QLabel("Percentage Threshold:")
        self.percentage_threshold_edit = QLineEdit("0")

        self.dilation_kernel_label = QLabel("Dilation Kernel:")
        self.dilation_kernel_edit = QLineEdit("0")

        self.oaf_check = QCheckBox("Override Actigraphy Files")
        self.set_roi_check = QCheckBox("Set Region of Interest (ROI)")
        self.name_stamp_check = QCheckBox("Use Name Stamp")
        self.name_stamp_check.setChecked(True)

        self.start_button = QPushButton("Start Actigraphy")
        self.start_button.clicked.connect(self.start_actigraphy)

        self.progress_bar = QProgressBar(self)

        self.btn_most_movement = QPushButton("Most Movement")
        self.btn_medium_movement = QPushButton("Medium Movement")
        self.btn_only_large_movement = QPushButton("Only Large Movement")

        self.btn_most_movement.clicked.connect(lambda: self.set_defaults(self.settings_most_movement))
        self.btn_medium_movement.clicked.connect(lambda: self.set_defaults(self.settings_medium_movement))
        self.btn_only_large_movement.clicked.connect(lambda: self.set_defaults(self.settings_only_large_movement))

        self.output_directory_label = QLabel("Output CSV File:")
        self.output_directory_edit = QLineEdit()
        self.output_directory_button = QPushButton("Select Output File Destination")
        self.output_directory_button.clicked.connect(self.select_output_file_destination)

        #formally adds all widgets
        layout.addWidget(self.btn_most_movement)
        layout.addWidget(self.btn_medium_movement)
        layout.addWidget(self.btn_only_large_movement)
        layout.addWidget(self.progress_bar)
        layout.addWidget(self.video_file_label)
        layout.addWidget(self.video_file_edit)
        layout.addWidget(self.video_file_button)
        layout.addWidget(self.video_folder_label)
        layout.addWidget(self.video_folder_edit)
        layout.addWidget(self.video_folder_button)
        layout.addWidget(self.min_size_threshold_label)
        layout.addWidget(self.min_size_threshold_edit)
        layout.addWidget(self.global_threshold_label)
        layout.addWidget(self.global_threshold_edit)
        layout.addWidget(self.percentage_threshold_label)
        layout.addWidget(self.percentage_threshold_edit)
        layout.addWidget(self.dilation_kernel_label)
        layout.addWidget(self.dilation_kernel_edit)
        layout.addWidget(self.oaf_check)
        layout.addWidget(self.set_roi_check)
        layout.addWidget(self.name_stamp_check)
        layout.addWidget(self.start_button)
        layout.addWidget(self.output_directory_label)
        layout.addWidget(self.output_directory_edit)
        layout.addWidget(self.output_directory_button)

        # Create a container widget for the layout
        container = QWidget()
        container.setLayout(layout)

        # Set the layout container as the scroll area's widget
        self.scroll_area.setWidget(container)

        # Create a new layout to hold the scroll area
        main_layout = QVBoxLayout()
        main_layout.addWidget(self.scroll_area)

        # Set the main layout for the window
        self.setLayout(main_layout)
        self.setWindowTitle('Actigraphy')
    
        # Set the minimum width and maximum height of the window
        self.setMinimumWidth(800)
        self.setMaximumHeight(600)

    def set_defaults(self, settings):
        # Update line edits with default values
        self.global_threshold_edit.setText(settings['global_threshold'])
        self.percentage_threshold_edit.setText(settings['percentage_threshold'])
        self.min_size_threshold_edit.setText(settings['min_size_threshold'])
        self.dilation_kernel_edit.setText(settings['dilation_kernel'])
    
    def select_output_file_destination(self):
        options = QFileDialog.Options()
        options |= QFileDialog.DontUseNativeDialog
        directory = QFileDialog.getExistingDirectory(
            self,
            "Select Output Directory",
            "",  # You can specify a default path here
            options=options
        )
        if directory:
            # Assuming you want to set the output directory to a class member
            self.output_directory = directory
            self.output_directory_edit.setText(directory)

    def browse_video_file(self):
        file_name, _ = QFileDialog.getOpenFileName(self, 'Open Video File', '', 'MP4 files (*.mp4)')
        self.video_file_edit.setText(file_name)

    def browse_video_folder(self):
        dir_name = QFileDialog.getExistingDirectory(self, 'Open Video Folder')
        self.video_folder_edit.setText(dir_name)

    def start_actigraphy(self):
        video_file = self.video_file_edit.text()
        video_folder = self.video_folder_edit.text()
        
        user_selected_output_dir = self.output_directory_edit.text().strip() # User's choice from GUI

        try:
            min_size_threshold = int(self.min_size_threshold_edit.text())
            global_threshold = int(self.global_threshold_edit.text())
            percentage_threshold = int(self.percentage_threshold_edit.text())
            dilation_kernel = int(self.dilation_kernel_edit.text())
        except ValueError as ve:
            QMessageBox.warning(self, "Input Error", f"Please enter valid integer values for thresholds and dilation kernel: {ve}")
            return

        oaf = self.oaf_check.isChecked()
        set_roi = self.set_roi_check.isChecked()
        name_stamp = self.name_stamp_check.isChecked()

        self.actigraphy_processor.min_size_threshold = min_size_threshold
        self.actigraphy_processor.global_threshold = global_threshold
        self.actigraphy_processor.percentage_threshold = percentage_threshold
        self.actigraphy_processor.dilation_kernel = dilation_kernel
        # Clear previous ROI if any, it will be re-determined per run
        self.actigraphy_processor.roi_pts = None 


        self.start_button.setEnabled(False)
        
        # Set output path for data CSVs
        if user_selected_output_dir:
            self.actigraphy_processor.output_file_path = user_selected_output_dir # Used by process_single_video for data CSV
        else:
            self.actigraphy_processor.output_file_path = None


        if video_file:
            self.processing_settings_for_metadata = {
                'mode': 'single',
                'input_path': video_file,
                'base_name': os.path.splitext(os.path.basename(video_file))[0],
                'user_specified_output_dir': user_selected_output_dir,
                'set_roi_option': set_roi,
                'name_stamp_option': name_stamp
            }
            # Positional args for process_single_video_file before roi_to_apply and progress_callback:
            # video_file_path, name_stamp_option, set_roi_user_choice, output_dir_for_data_csv
            self.worker = Worker(self.actigraphy_processor.process_single_video_file,
                                 video_file,                 # video_file_path
                                 name_stamp,                 # name_stamp_option
                                 set_roi,                    # set_roi_user_choice
                                 user_selected_output_dir    # output_dir_for_data_csv
                                 # roi_to_apply will use its default of None
                                 # progress_callback will be passed via kwargs
                                )
            self.worker.kwargs['progress_callback'] = self.worker.progress_signal # Correctly pass as kwarg
            self.worker.progress_signal.connect(self.update_progress_bar)
            self.worker.finished.connect(self.on_processing_finished)
            self.worker.start()
        elif video_folder:
            self.processing_settings_for_metadata = {
                'mode': 'folder',
                'input_path': video_folder,
                'base_name': os.path.basename(video_folder.rstrip('/\\')),
                'user_specified_output_dir': user_selected_output_dir,
                'set_roi_option': set_roi,
                'name_stamp_option': name_stamp
            }
            # Positional args for process_video_files before progress_callback:
            # video_folder, oaf, set_roi_option, name_stamp_option, user_specified_output_dir
            self.worker = Worker(
                self.actigraphy_processor.process_video_files,
                video_folder,                 # video_folder
                oaf,                          # oaf
                set_roi,                      # set_roi_option
                name_stamp,                   # name_stamp_option
                user_selected_output_dir      # user_specified_output_dir
                # progress_callback will be passed via kwargs
            )
            self.worker.kwargs['progress_callback'] = self.worker.progress_signal # Correctly pass as kwarg
            self.worker.progress_signal.connect(self.update_folder_progress_bar)
            self.worker.finished.connect(self.on_processing_finished)
            self.worker.start()
        else:
            QMessageBox.information(self, "No Input", "No video file or folder has been selected.")
            self.start_button.setEnabled(True)
        
    def update_progress_bar(self, value):
        self.progress_bar.setValue(value)

    def update_folder_progress_bar(self, value):
        self.progress_bar.setValue(value)

    def on_processing_finished(self):
        self.progress_bar.setValue(100) # Ensure it's 100%
        QMessageBox.information(self, "Actigraphy Processing", "Actigraphy processing has been completed.")
        
        # Generate metadata for single file processing mode
        if self.processing_settings_for_metadata.get('mode') == 'single':
            s = self.processing_settings_for_metadata
            # self.actigraphy_processor.roi_pts will be set (or None if cancelled) 
            # by the completed process_single_video_file call.
            # Thresholds are already set on self.actigraphy_processor instance.
            self.actigraphy_processor.generate_metadata_csv(
                s['base_name'],
                s['input_path'],
                s['set_roi_option'],
                s['name_stamp_option'],
                s['user_specified_output_dir']
            )
        
        self.processing_settings_for_metadata = {} # Reset
        self.start_button.setEnabled(True)

class ActigraphyProcessor:
    def __init__(self):
        self.roi_pts = None
        self.output_file_path = None  # For data CSVs, set by ActigraphyProcessorApp
        self.min_size_threshold = 0.0
        self.global_threshold = 0.0
        self.percentage_threshold = 0.0
        self.dilation_kernel = 0

    def generate_metadata_csv(self, base_output_name, input_path_str,
                              user_selected_set_roi_option, user_selected_name_stamp_option,
                              user_specified_output_dir):
        """
        Generates a CSV file containing metadata about the processing run.
        """
        actual_save_dir = user_specified_output_dir
        if not actual_save_dir:  # If user didn't specify an output directory
            if os.path.isfile(input_path_str):
                actual_save_dir = os.path.dirname(input_path_str)
            elif os.path.isdir(input_path_str):
                actual_save_dir = input_path_str
            else:
                print(f"Warning: Could not determine save directory for metadata for {input_path_str}. Skipping metadata file.")
                return

        if not os.path.exists(actual_save_dir):
            try:
                os.makedirs(actual_save_dir, exist_ok=True)
            except OSError as e:
                print(f"Error: Could not create directory {actual_save_dir} for metadata CSV: {e}. Skipping.")
                return

        metadata_filename = f"{base_output_name}_MetaData.csv"
        metadata_filepath = os.path.join(actual_save_dir, metadata_filename)

        script_name = os.path.basename(sys.argv[0])
        processing_time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

        data_to_write = [
            ("Python Script Name", script_name),
            ("Processing Settings Applied Time", processing_time),
            ("Input Path/Identifier", input_path_str),
            ("Global Threshold", self.global_threshold),
            ("Percentage Threshold", self.percentage_threshold),
            ("Minimum Size Threshold", self.min_size_threshold),
            ("Dilation Kernel", self.dilation_kernel),
            ("ROI Option Selected by User", user_selected_set_roi_option),
        ]

        roi_coords_str = "N/A (ROI not selected by user)"
        if user_selected_set_roi_option:
            if self.roi_pts and isinstance(self.roi_pts, tuple) and len(self.roi_pts) == 4 and self.roi_pts[2] > 0 and self.roi_pts[3] > 0:
                roi_coords_str = str(self.roi_pts)
            elif self.roi_pts:
                roi_coords_str = f"ROI data recorded: {self.roi_pts} (Check if width/height are > 0 for valid application)"
            else:
                roi_coords_str = "User cancelled ROI selection, or selection was invalid/not made"

        data_to_write.append(("ROI Coordinates (x,y,w,h) Applied", roi_coords_str))
        timestamp_source = "Filename Timestamp" if user_selected_name_stamp_option else "File System Metadata Timestamp"
        data_to_write.append(("Timestamp Source Option", timestamp_source))

        try:
            with open(metadata_filepath, 'w', newline='') as mf:
                csv_writer = csv.writer(mf)
                csv_writer.writerow(["Parameter", "Value"])
                csv_writer.writerows(data_to_write)
            print(f"Metadata CSV saved to: {metadata_filepath}")
        except Exception as e:
            print(f"Error writing metadata CSV to {metadata_filepath}: {e}")

    def get_nested_paths(self, root_dir):
        queue = [root_dir]
        paths = []
        print('Here are all the nested folders within the selected directory:')
        while queue:
            current_dir = queue.pop(0)
            paths.append(current_dir)
            print(current_dir) # Keep this print or remove if too verbose

            for child_dir_name in sorted(os.listdir(current_dir)):
                child_path = os.path.join(current_dir, child_dir_name)
                if os.path.isdir(child_path):
                    queue.append(child_path)
        return paths

    def list_mp4_files(self, directory_path, output_check_directory, oaf):
        mp4_files = [f for f in os.listdir(directory_path) if f.lower().endswith('.mp4')]
        # Check for existing CSVs in the output_check_directory (where data CSVs will go)
        # or in the source directory_path if output_check_directory is the same as source.
        csv_files_in_output = []
        if os.path.exists(output_check_directory):
            csv_files_in_output = [f for f in os.listdir(output_check_directory) if f.lower().endswith('_actigraphy.csv')]

        updated_mp4_files = []
        if mp4_files:
            print(f"List of MP4 files in {directory_path}: ")
            for mp4_file in mp4_files:
                print(mp4_file)
                # Construct the expected actigraphy CSV filename
                expected_csv_name = os.path.splitext(mp4_file)[0] + "_actigraphy.csv"
                
                # Check if this CSV exists in the output_check_directory
                if expected_csv_name in csv_files_in_output:
                    print(f"Actigraphy file already found for {mp4_file} in target output location.")
                    if oaf:
                        print("Override Actigraphy Files set True. Redoing this file.")
                    else:
                        continue # Skip this file
                updated_mp4_files.append(mp4_file) # Keep full name, path joining happens later
            mp4_files = updated_mp4_files
        else:
            print(f"No MP4 files found in {directory_path}.")
        return mp4_files

    def _select_roi_from_first_frame(self, cap):
        ret, frame = cap.read()
        if not ret:
            return None
        
        window_name = "Select ROI for Folder/File (ENTER/SPACE to confirm, C/ESC to cancel)"
        print(f"ROI Selection: Displaying frame. In \"{window_name}\" window, select ROI then press ENTER or SPACE. Press C or ESC to cancel.")
        # cv2.namedWindow(window_name, cv2.WINDOW_NORMAL) # Optional: make resizable
        # cv2.resizeWindow(window_name, frame.shape[1]//2, frame.shape[0]//2) # Optional: make smaller
        
        roi_coords = cv2.selectROI(window_name, frame, showCrosshair=True, fromCenter=False)
        cv2.destroyWindow(window_name)

        if roi_coords == (0,0,0,0): # selection cancelled
            print("ROI selection cancelled by user.")
            return None
        return roi_coords

    def _apply_roi(self, frame, roi_pts):
        x, y, w, h = roi_pts
        # Ensure ROI coordinates are integers and valid
        x, y, w, h = int(x), int(y), int(w), int(h)
        if w > 0 and h > 0:
             return frame[y:y+h, x:x+w]
        return frame # Return original frame if ROI is invalid

    def process_video_files(self, video_folder, oaf, set_roi_option, name_stamp_option,
                        user_specified_output_dir, progress_callback=None):
        start_time = time.time()
        total_frames_processed_overall = 0
        
        # self.roi_pts is assumed to be cleared by ActigraphyProcessorApp before this call for a new batch

        nested_folders = self.get_nested_paths(video_folder)
        all_mp4_files_to_process = []
        for current_folder_path in nested_folders:
            # Determine where to check for existing CSVs for list_mp4_files
            # If user specified an output dir, check there. Otherwise, check in the source folder.
            dir_to_check_for_csvs = user_specified_output_dir if user_specified_output_dir else current_folder_path
            
            mp4_filenames_in_folder = self.list_mp4_files(current_folder_path, dir_to_check_for_csvs, oaf)
            for mp4_filename in mp4_filenames_in_folder:
                 all_mp4_files_to_process.append(os.path.join(current_folder_path, mp4_filename))

        total_files = len(all_mp4_files_to_process)
        if total_files == 0:
            print("No video files to process in the selected folder and its subfolders (after checking for overrides).")
            if progress_callback: progress_callback.emit(100)
            # Still generate metadata if the folder itself was selected, even if no files found after filtering
            folder_basename = os.path.basename(video_folder.rstrip('/\\'))
            self.generate_metadata_csv(folder_basename, video_folder, set_roi_option,
                                       name_stamp_option, user_specified_output_dir)
            return

        if set_roi_option and not self.roi_pts: # Only attempt to set if user wants it and it's not already set
            first_video_file_for_roi = all_mp4_files_to_process[0]
            cap_for_roi = cv2.VideoCapture(first_video_file_for_roi)
            if cap_for_roi.isOpened():
                print(f"ROI Selection: Opening first video ({os.path.basename(first_video_file_for_roi)}) to select ROI for the folder.")
                selected_roi_for_folder = self._select_roi_from_first_frame(cap_for_roi)
                if selected_roi_for_folder and selected_roi_for_folder[2] > 0 and selected_roi_for_folder[3] > 0:
                    self.roi_pts = selected_roi_for_folder
                    print(f"ROI for folder set to: {self.roi_pts}")
                else:
                    print("ROI selection cancelled or invalid for the folder. Proceeding without applying ROI.")
                    self.roi_pts = None
                cap_for_roi.release()
            else:
                print(f"Failed to open the first video file for ROI selection: {first_video_file_for_roi}. Proceeding without ROI.")
                self.roi_pts = None # Ensure it's None

        # Generate metadata CSV for the folder after ROI determination
        folder_basename = os.path.basename(video_folder.rstrip('/\\'))
        self.generate_metadata_csv(folder_basename, video_folder, set_roi_option,
                                   name_stamp_option, user_specified_output_dir)

        files_processed_count = 0
        for mp4_full_path in all_mp4_files_to_process:
            # output_dir_for_data_csv is user_specified_output_dir from ActigraphyProcessorApp
            # roi_to_apply is self.roi_pts (the one potentially set for the folder)
            self.process_single_video_file(mp4_full_path, name_stamp_option, set_roi_option,
                                           user_specified_output_dir,
                                           None, # No individual file progress bar update from here
                                           self.roi_pts) # Pass the folder-wide ROI
            
            files_processed_count += 1
            cap_temp = cv2.VideoCapture(mp4_full_path) # Re-open to get frame count
            if cap_temp.isOpened():
                total_frames_processed_overall += int(cap_temp.get(cv2.CAP_PROP_FRAME_COUNT))
                cap_temp.release()

            if progress_callback:
                folder_progress = int((files_processed_count / total_files) * 100)
                progress_callback.emit(folder_progress)
        
        end_time = time.time()
        total_time_taken = end_time - start_time
        time_per_frame = total_time_taken / total_frames_processed_overall if total_frames_processed_overall else float('inf')
        print("\n--- FOLDER PROCESSING SUMMARY ---")
        print(f"Total Videos Processed: {files_processed_count}")
        print(f"Total Time Taken for All Videos: {total_time_taken:.2f} seconds")
        print(f"Total Frames Processed for All Videos: {total_frames_processed_overall}")
        print(f"Average Time Per Frame for All Videos: {time_per_frame:.4f} seconds")
        print("-" * 30)

        if progress_callback:
            progress_callback.emit(100)

    def process_single_video_file(self, video_file_path, name_stamp_option, set_roi_user_choice,
                              output_dir_for_data_csv, roi_to_apply=None, progress_callback=None):
        if name_stamp_option: # Simplified from original (name_stamp or name_stamp is None)
            creation_time = self._get_creation_time_from_name(video_file_path)
        else:
            creation_time = int(os.path.getctime(video_file_path) * 1000)

        cap = cv2.VideoCapture(video_file_path)
        if not cap.isOpened():
            print(f"Error: Could not open video file {video_file_path}")
            if progress_callback: progress_callback.emit(100) # Mark as done if error
            return

        # Determine actual ROI to use for this file.
        # self.roi_pts is the instance's current ROI state.
        # For a true single file run (not part of batch), roi_to_apply would be None.
        # ActigraphyProcessorApp clears self.roi_pts before a run.
        current_file_roi = None
        if set_roi_user_choice:
            if roi_to_apply and roi_to_apply[2] > 0 and roi_to_apply[3] > 0: # Valid ROI passed from folder context
                current_file_roi = roi_to_apply
                self.roi_pts = current_file_roi # Ensure instance reflects this
            elif not roi_to_apply and self.roi_pts is None: # True single file, needs ROI selection
                print(f"ROI Selection: Opening video ({os.path.basename(video_file_path)}) to select ROI.")
                # Need a temporary capture object if main 'cap' is already in use or to avoid state issues
                # However, 'cap' is freshly opened here, so we can use it if we reset it.
                # Simpler: re-open or use a fresh one.
                temp_cap_for_roi = cv2.VideoCapture(video_file_path)
                if temp_cap_for_roi.isOpened():
                    selected_roi = self._select_roi_from_first_frame(temp_cap_for_roi)
                    if selected_roi and selected_roi[2] > 0 and selected_roi[3] > 0:
                        self.roi_pts = selected_roi # This sets it for the App to pick up later for single file metadata
                        current_file_roi = self.roi_pts
                    else:
                        self.roi_pts = None # Explicitly None if cancelled/invalid
                        current_file_roi = None
                    temp_cap_for_roi.release()
                else: # Should not happen if main cap opened
                    print(f"Could not re-open video {video_file_path} to select ROI.")
                    self.roi_pts = None
                    current_file_roi = None
            elif self.roi_pts and self.roi_pts[2] > 0 and self.roi_pts[3] > 0: # ROI already set on instance (e.g. by previous single file)
                 current_file_roi = self.roi_pts
        
        # Data CSV path
        data_csv_filename = os.path.splitext(os.path.basename(video_file_path))[0] + "_actigraphy.csv"
        if output_dir_for_data_csv:
            data_csv_full_path = os.path.join(output_dir_for_data_csv, data_csv_filename)
        else:
            data_csv_full_path = os.path.join(os.path.dirname(video_file_path), data_csv_filename)

        prev_frame_processed = None # Stores the (potentially ROI'd) previous frame
        frame_number = 0
        result_rows = []
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

        print(f"\nProcessing video file: {video_file_path}")
        if current_file_roi:
            print(f"Applying ROI: {current_file_roi}")
        else:
            print("Processing full frame (no ROI or ROI invalid/cancelled).")

        with open(data_csv_full_path, 'w', newline='') as output_file:
            writer = csv.writer(output_file)
            writer.writerow(['Frame', 'TimeElapsedMicros', 'RawDifference', 'RMSE', 'SelectedPixelDifference', 'POSIX'])
            writer.writerow([0, 0, 0, 0, 0, creation_time]) # Initial state row

            while True:
                ret, frame = cap.read()
                if not ret:
                    break
                frame_number += 1
                elapsed_millis = cap.get(cv2.CAP_PROP_POS_MSEC)

                frame_to_process = frame.copy() # Work on a copy
                if current_file_roi: # Apply ROI if one is set and valid for this file
                    frame_to_process = self._apply_roi(frame_to_process, current_file_roi)

                if prev_frame_processed is not None:
                    # Ensure dimensions match if ROI is applied inconsistently (should not happen with this logic)
                    if frame_to_process.shape != prev_frame_processed.shape:
                        print(f"Warning: Frame shape mismatch between current ({frame_to_process.shape}) and previous ({prev_frame_processed.shape}). This may occur if ROI changes mid-processing or at the start. Skipping metrics for this frame.")
                        # Re-initialize prev_frame_processed or skip
                        prev_frame_processed = frame_to_process.copy()
                        continue


                    raw_diff, rmse, selected_pixel_diff = self._calculate_metrics(
                        frame_to_process, prev_frame_processed,
                        float(self.global_threshold), float(self.min_size_threshold),
                        float(self.percentage_threshold), int(self.dilation_kernel)
                    )
                    posix_time = int(creation_time + elapsed_millis)
                    result_rows.append([frame_number, elapsed_millis, raw_diff, rmse, selected_pixel_diff, posix_time])
                    if len(result_rows) >= 1000: # Batch write
                        writer.writerows(result_rows)
                        result_rows = []
                
                prev_frame_processed = frame_to_process.copy() # Store the (potentially ROI'd) frame

                if progress_callback and frame_number % 100 == 0:
                    progress = (frame_number / total_frames) * 100 if total_frames > 0 else 0
                    progress_callback.emit(int(progress))

            if result_rows: # Write any remaining rows
                writer.writerows(result_rows)
        
        cap.release()
        if progress_callback: progress_callback.emit(100) # Ensure completion
        print(f"Actigraphy data CSV saved to {data_csv_full_path}")
        print("-" * 75)

    @staticmethod
    def _calculate_metrics(frame, prev_frame, global_threshold, min_size_threshold, percentage_threshold, dilation_kernel_size):
        # Ensure frames are grayscale if not already
        if len(frame.shape) == 3 and frame.shape[2] == 3:
            frame_gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        else:
            frame_gray = frame # Assume already grayscale

        if len(prev_frame.shape) == 3 and prev_frame.shape[2] == 3:
            prev_frame_gray = cv2.cvtColor(prev_frame, cv2.COLOR_BGR2GRAY)
        else:
            prev_frame_gray = prev_frame # Assume already grayscale

        abs_diff = np.abs(frame_gray.astype(np.float32) - prev_frame_gray.astype(np.float32))
        raw_diff = np.sum(abs_diff)
        rmse = np.sqrt(np.mean(abs_diff ** 2))

        prev_frame_safe = prev_frame_gray.astype(np.float32) + 1e-5
        percentage_change = np.abs((frame_gray.astype(np.float32) - prev_frame_safe) / prev_frame_safe)
        
        _, abs_diff_mask = cv2.threshold(abs_diff, global_threshold, 255, cv2.THRESH_BINARY)
        percentage_change_scaled = np.clip(percentage_change * 100, 0, 100).astype(np.uint8)
        _, percentage_change_mask = cv2.threshold(percentage_change_scaled, percentage_threshold, 255, cv2.THRESH_BINARY)

        abs_diff_mask = abs_diff_mask.astype(np.uint8)
        percentage_change_mask = percentage_change_mask.astype(np.uint8)
        combined_mask = cv2.bitwise_and(abs_diff_mask, percentage_change_mask)
        
        if dilation_kernel_size > 0:
            kernel = np.ones((dilation_kernel_size, dilation_kernel_size), np.uint8)
            dilated_mask = cv2.dilate(combined_mask, kernel, iterations=1)
        else: # No dilation if kernel size is 0 or less
            dilated_mask = combined_mask
        
        num_labels, labels, stats, _ = cv2.connectedComponentsWithStats(dilated_mask, connectivity=8)
        filtered_mask = np.zeros_like(dilated_mask)
        if num_labels > 1: # If there are components other than background
            component_areas = stats[1:, cv2.CC_STAT_AREA]
            large_components_indices = np.where(component_areas >= min_size_threshold)[0] + 1 # +1 to match label numbers
            for label_idx in large_components_indices:
                filtered_mask[labels == label_idx] = 255
        
        selected_pixel_diff = np.sum(filtered_mask) / 255 # Count of white pixels
        return raw_diff, rmse, selected_pixel_diff

    @staticmethod
    def _get_creation_time_from_name(filename):
        regex_pattern = r'RBB01_T(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})(\d{3})'
        match = re.search(regex_pattern, os.path.basename(filename))
        if match:
            year, month, day, hour, minute, second, millisecond = match.groups()
            date_time_str = f"{year}{month}{day}{hour}{minute}{second}"
            date_time_format = '%Y%m%d%H%M%S'
            try:
                date_time_obj = datetime.strptime(date_time_str, date_time_format)
                posix_timestamp_ms = int(date_time_obj.timestamp() * 1000) + int(millisecond)
                return posix_timestamp_ms
            except ValueError: # Handle cases like invalid date (e.g. Feb 30)
                 print(f"Warning: Could not parse valid date from filename pattern: {date_time_str}. Using file generated time.")
                 return int(os.path.getctime(filename) * 1000)
        else:
            print(f"Failed to extract creation time from the file name using pattern. Using file generated time for {os.path.basename(filename)}.")
            return int(os.path.getctime(filename) * 1000)

if __name__ == "__main__":

    # Launching the PyQt5 application
    app = QApplication(sys.argv)
    
    actigraphy_processor = ActigraphyProcessor()  # Instantiate the main logic class

    # The ActigraphyProcessorApp now takes the main logic class as an argument
    window = ActigraphyProcessorApp(actigraphy_processor)
    window.show()

    sys.exit(app.exec_())