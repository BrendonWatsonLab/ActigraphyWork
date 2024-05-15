import cv2
import csv
import sys
from PyQt5.QtWidgets import QApplication, QWidget, QLabel, QLineEdit, QPushButton, QFileDialog, QCheckBox, QVBoxLayout
from PyQt5.QtCore import QThread
from PyQt5.QtWidgets import QProgressBar
from PyQt5.QtCore import pyqtSignal
import numpy as np
import argparse
import os
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
        # can edit three default settings for buttons
        self.actigraphy_processor = actigraphy_processor
        self.settings_most_movement = {'global_threshold': '10', 'percentage_threshold': '20', 'min_size_threshold': '100', 'dilation_kernel': '3'}
        self.settings_medium_movement = {'global_threshold': '15', 'percentage_threshold': '25', 'min_size_threshold': '120', 'dilation_kernel': '4'}
        self.settings_only_large_movement = {'global_threshold': '20', 'percentage_threshold': '30', 'min_size_threshold': '140', 'dilation_kernel': '5'}
        self.init_ui()

    def init_ui(self):
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

        self.setLayout(layout)
        self.setWindowTitle('Actigraphy')

    def set_defaults(self, settings):
        # Update line edits with default values
        self.global_threshold_edit.setText(settings['global_threshold'])
        self.percentage_threshold_edit.setText(settings['percentage_threshold'])
        self.min_size_threshold_edit.setText(settings['min_size_threshold'])
        self.dilation_kernel_edit.setText(settings['dilation_kernel'])

    def browse_video_file(self):
        file_name, _ = QFileDialog.getOpenFileName(self, 'Open Video File', '', 'MP4 files (*.mp4)')
        self.video_file_edit.setText(file_name)

    def browse_video_folder(self):
        dir_name = QFileDialog.getExistingDirectory(self, 'Open Video Folder')
        self.video_folder_edit.setText(dir_name)

    def start_actigraphy(self):
        # Retrieve the file path or directory from the QLineEdit widgets
        video_file = self.video_file_edit.text()
        video_folder = self.video_folder_edit.text()

        try:
            # Get thresholding and kernel parameters from the QLineEdit widgets
            min_size_threshold = int(self.min_size_threshold_edit.text())
            global_threshold = int(self.global_threshold_edit.text())
            percentage_threshold = int(self.percentage_threshold_edit.text())
            dilation_kernel = int(self.dilation_kernel_edit.text())
        except ValueError as ve:
            print("Please enter valid integer values for thresholds and dilation kernel.", ve)
            return

        # Get the checkbox states
        oaf = self.oaf_check.isChecked()
        set_roi = self.set_roi_check.isChecked()
        name_stamp = self.name_stamp_check.isChecked()

        # Set the processor's attributes
        self.actigraphy_processor.min_size_threshold = min_size_threshold
        self.actigraphy_processor.global_threshold = global_threshold
        self.actigraphy_processor.percentage_threshold = percentage_threshold
        self.actigraphy_processor.dilation_kernel = dilation_kernel

        # Disable start button to prevent multiple concurrent operations
        self.start_button.setEnabled(False)

        # Check if a single video file or video directory has been specified
        if video_file:
            self.worker = Worker(self.actigraphy_processor.process_single_video_file,
                                 video_file, name_stamp, set_roi)
            # Now correctly pass the progress_callback as an argument to process_single_video_file
            self.worker.kwargs['progress_callback'] = self.worker.progress_signal
            # Connect signals
            self.worker.progress_signal.connect(self.update_progress_bar)
            self.worker.finished.connect(self.on_processing_finished)
            self.worker.start()
        elif video_folder:
            # Create the worker for processing the folder
            self.worker = Worker(
                self.actigraphy_processor.process_video_files, 
                video_folder, oaf, set_roi, name_stamp
            )
        
            # Connect the progress signal before starting the worker
            self.worker.kwargs['progress_callback'] = self.worker.progress_signal
            self.worker.progress_signal.connect(self.update_progress_bar)
            self.worker.finished.connect(self.on_processing_finished)
            self.worker.start()
        else:
            print("No video file or folder has been selected.")
            self.start_button.setEnabled(True)
        
    def update_progress_bar(self, value):
        self.progress_bar.setValue(value)

    def on_processing_finished(self):
        print("Actigraphy processing has been completed.")
        self.start_button.setEnabled(True)  # Re-enable the start button

class ActigraphyProcessor:
    def __init__(self):
        self.roi_pts=None
        self.min_size_threshold = 0.0
        self.global_threshold = 0.0
        self.percentage_threshold = 0.0
        self.dilation_kernel = 0

    def get_nested_paths(self, root_dir):
        queue = [root_dir]
        paths = []
        print('Here are all the nested folders within the selected directory:')
        while queue:
            current_dir = queue.pop(0)
            paths.append(current_dir)
            print(current_dir)

            for child_dir in sorted(os.listdir(current_dir)):
                child_path = os.path.join(current_dir, child_dir)
                if os.path.isdir(child_path):
                    queue.append(child_path)

        return paths

    def list_mp4_files(self, directory_path, oaf):
        mp4_files = [f for f in os.listdir(directory_path) if f.endswith('.mp4')]
        csv_files = [f for f in os.listdir(directory_path) if f.endswith('.csv')]
        
        if mp4_files:
            updated_mp4_files = []
            print("List of all the MP4 files in {}: ".format(directory_path))
            for mp4_file in mp4_files:
                print(mp4_file)
                if mp4_file[:-4] + "_actigraphy.csv" in csv_files:
                    print("Actigraphy file already found for {}.".format(mp4_file))
                    if oaf:
                        print("Overide Actigraphy Files set True, Redoing this file.")
                    else:
                        continue
                
                updated_mp4_files.append(mp4_file)
            mp4_files = updated_mp4_files
        else:
            print("No MP4 files found in {}.".format(directory_path))
        
        return mp4_files

    def process_single_video_file(self, video_file, name_stamp, set_roi, roi_pts=None, progress_callback=None):
        # Determine whether to use creation time from the file name or os.path.getctime
        if name_stamp or name_stamp is None:
            print("Extracting creation time from the name.")
            creation_time = self._get_creation_time_from_name(video_file)
        else:
            print("Using the file's actual creation time.")
            creation_time = int(os.path.getctime(video_file)*1000)
            

        cap = cv2.VideoCapture(video_file)
        prev_frame = None
        frame_number = 0

        # Output CSV file path
        # can edit file name here
        outputfile_name = os.path.splitext(os.path.basename(video_file))[0] + "_actigraphy.csv"
        # can edit file save path here
        save_directory = os.path.dirname(video_file)
        output_file_path = os.path.join(save_directory, outputfile_name)

        with open(output_file_path, 'w', newline='') as output_file:
            writer = csv.writer(output_file)
            writer.writerow(['Frame', 'TimeElapsedMicros', 'RawDifference', 'RMSE','SelectedPixelDifference'])

            if set_roi and self.roi_pts is None:
                # If set_roi is True and roi_pts is not provided, prompt the user to select ROI
                print("Please select the region of interest (ROI) in the first frame.")
                self.roi_pts = self._select_roi_from_first_frame(cap)
        
            print(f"\nProcessing video file: {video_file}")
            writer.writerow([1, 0, 0, 0, 0, creation_time])

            total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

            while True:
                ret, frame = cap.read()
                if not ret:
                    break
                frame_number += 1
                elapsed_millis = cap.get(cv2.CAP_PROP_POS_MSEC)

                if set_roi and self.roi_pts:
                    # Apply the ROI if set_roi is True
                    frame = self._apply_roi(frame, self.roi_pts)

                if prev_frame is not None:
                    raw_diff, rmse, selected_pixel_diff = self._calculate_metrics(frame, prev_frame, float(self.global_threshold), float(self.min_size_threshold), float(self.percentage_threshold), int(self.dilation_kernel))
                    # Calculate Posixtime based on creation time and elapsed time
                    posix_time = int(creation_time + (elapsed_millis))

                    # writes a line of the csv
                    writer.writerow([frame_number, elapsed_millis, raw_diff, rmse, selected_pixel_diff, posix_time])

                prev_frame = frame

                if progress_callback and frame_number % 100 == 0:  # Updates every 100 frames for progress bar
                    progress = (frame_number / total_frames) * 100
                    progress_callback.emit(int(progress))
            cap.release()
            print(f"Actigraphy processing completed for {video_file}")
            print("*" * 75)

    def process_video_files(self, video_folder, oaf, set_roi, name_stamp, progress_callback=None):
        nested_folders = self.get_nested_paths(video_folder)
        all_mp4_files = [
            os.path.join(folder, mp4_file)
            for folder in nested_folders
            for mp4_file in self.list_mp4_files(folder, oaf)
        ]
        total_files = len(all_mp4_files)
        files_processed = 0

        for mp4_file in all_mp4_files:
            # Process the single video file
            self.process_single_video_file(mp4_file, name_stamp, set_roi, self.roi_pts)
            
            # Increment the number of processed files
            files_processed += 1

            # Emit the updated cumulative progress for the entire folder
            if progress_callback:
                folder_progress = int((files_processed / total_files) * 100)
                progress_callback.emit(folder_progress)

            # Initialize roi_pts to None for the first video in the list, or retain previously set ROI
            if set_roi and not self.roi_pts:
                cap = cv2.VideoCapture(mp4_file)
                self.roi_pts = self._select_roi_from_first_frame(cap)
                cap.release()  # Make sure to release the capture object

    def _select_roi_from_first_frame(self, cap):
        # Open the first frame for user to select ROI points
        ret, frame = cap.read()
        if not ret:
            return None

        print("Select the region of interest (ROI) points in the first frame.")
        roi_pts = cv2.selectROI(frame)

        # Close the window after selecting ROI
        cv2.destroyAllWindows()

        return roi_pts

    def _apply_roi(self, frame, roi_pts):
       
		  # Apply the selected ROI to the frame
        x, y, w, h = roi_pts
        roi = frame[int(y):int(y + h), int(x):int(x + w)]
        return roi

    @staticmethod
    def _calculate_metrics(frame, prev_frame, global_threshold, min_size_threshold, percentage_threshold, dilation_kernel):
        frame = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        prev_frame = cv2.cvtColor(prev_frame, cv2.COLOR_BGR2GRAY)    
        	
        abs_diff = np.abs(frame - prev_frame)
        raw_diff = np.sum(abs_diff)
        rmse = (np.mean((frame - prev_frame) ** 2))**0.5
        
        prev_frame_safe = prev_frame.astype(np.float32) + 1e-5
        frame = frame.astype(np.float32)
	    
	     # Calculate absolute difference and percentage change
        abs_diff = np.abs(frame - prev_frame)
        percentage_change = np.abs((frame - prev_frame_safe) / prev_frame_safe)
	    
	     # Scale percentage change to 0-100 (adjust scaling factor as needed)
        percentage_change_scaled = np.clip(percentage_change * 100, 0, 100).astype(np.uint8)
	    
	     # Apply thresholds to get binary masks
        _, abs_diff_mask = cv2.threshold(abs_diff, global_threshold, 255, cv2.THRESH_BINARY)
        _, percentage_change_mask = cv2.threshold(percentage_change_scaled, percentage_threshold, 100, cv2.THRESH_BINARY)
        abs_diff_mask = abs_diff_mask.astype(np.uint8)
        percentage_change_mask = percentage_change_mask.astype(np.uint8)

	     # Combine masks using logical AND to require both conditions to be met
        combined_mask = cv2.bitwise_and(abs_diff_mask, percentage_change_mask)
        
        kernel = np.ones((dilation_kernel, dilation_kernel), np.uint8)
        dilated_diff = cv2.dilate(combined_mask, kernel, iterations=1)
        dilated_diff = dilated_diff.astype(np.uint8)

        # filters small regions
        binary_image = dilated_diff
        num_labels, labels, stats, _ = cv2.connectedComponentsWithStats(binary_image, connectivity=8)

        filtered_image = np.zeros_like(binary_image)
        for label in range(1, num_labels):
            if stats[label, cv2.CC_STAT_AREA] >= min_size_threshold:
                filtered_image[labels == label] = 255

        selected_pixel_diff = np.sum(filtered_image)
        return raw_diff, rmse, selected_pixel_diff

    @staticmethod
    def _get_creation_time_from_name(filename):
        regex_pattern_1 = r'(\d{8}_\d{9})'
        regex_pattern_2 = r'(\d{8}_\d{6})'
        
        # Try the first regex pattern
        match = re.search(regex_pattern_1, os.path.basename(filename))
        
        if match:
            # Extract the matched date and time
            date_time_str = match.group(1)
            #print(date_time_str)
            # Include milliseconds in the format
            date_time_format = '%Y%m%d_%H%M%S%f'
            
            # Convert the date and time string to a datetime object
            date_time_obj = datetime.strptime(date_time_str, date_time_format)
            
            # Get the POSIX timestamp in milliseconds
            posix_timestamp_ms = int(date_time_obj.timestamp() * 1000)
            
            return posix_timestamp_ms
        else:
            # If the first pattern didn't match, try the second pattern
            match = re.search(regex_pattern_2, os.path.basename(filename))
            
            if match:
                # Extract the matched date and time from the second pattern
                date_time_str = match.group(1)
                
                # Include milliseconds in the format
                date_time_format = '%Y%m%d_%H%M%S'
                
                # Convert the date and time string to a datetime object
                date_time_obj = datetime.strptime(date_time_str, date_time_format)
                
                # Get the POSIX timestamp in milliseconds
                posix_timestamp_ms = int(date_time_obj.timestamp() * 1000)
                
                return posix_timestamp_ms
            else:
                print("Failed to extract creation time from the file name. Using file generated time instead.")
                return int(os.path.getctime(filename)*1000)


if __name__ == "__main__":

    # Launching the PyQt5 application
    app = QApplication(sys.argv)
    
    actigraphy_processor = ActigraphyProcessor()  # Instantiate the main logic class

    # The ActigraphyProcessorApp now takes the main logic class as an argument
    window = ActigraphyProcessorApp(actigraphy_processor)
    window.show()

    sys.exit(app.exec_())