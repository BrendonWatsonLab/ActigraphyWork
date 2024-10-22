# exact same logic as v5, except using tkinter instead of pyqt5

import cv2
import csv
import sys
import time
import numpy as np
import os
import re
import datetime
from datetime import datetime
import threading
from tkinter import *
from tkinter import filedialog, messagebox, ttk

class ActigraphyProcessorApp:
    def __init__(self, root, actigraphy_processor):
        self.root = root
        self.actigraphy_processor = actigraphy_processor
        self.output_directory = None
        self.settings_most_movement = {'global_threshold': '15', 'percentage_threshold': '25', 'min_size_threshold': '120', 'dilation_kernel': '4'}
        self.settings_medium_movement = {'global_threshold': '30', 'percentage_threshold': '35', 'min_size_threshold': '160', 'dilation_kernel': '3'}
        self.settings_only_large_movement = {'global_threshold': '40', 'percentage_threshold': '50', 'min_size_threshold': '200', 'dilation_kernel': '2'}
        self.init_ui()

    def init_ui(self):
        self.root.title("Actigraphy")
        self.root.geometry("800x600")
        main_frame = Frame(self.root)
        main_frame.pack(fill=BOTH, expand=1)
        canvas = Canvas(main_frame)
        canvas.pack(side=LEFT, fill=BOTH, expand=1)
        scrollbar = ttk.Scrollbar(main_frame, orient=VERTICAL, command=canvas.yview)
        scrollbar.pack(side=RIGHT, fill=Y)
        canvas.configure(yscrollcommand=scrollbar.set)
        canvas.bind('<Configure>', lambda e: canvas.configure(scrollregion=canvas.bbox("all")))
        content_frame = Frame(canvas)
        canvas.create_window((0, 0), window=content_frame, anchor="nw")

        self.video_file_label = Label(content_frame, text="Video File:")
        self.video_file_label.pack()
        self.video_file_edit = Entry(content_frame, width=100)
        self.video_file_edit.pack()
        self.video_file_button = Button(content_frame, text="Browse Files", command=self.browse_video_file)
        self.video_file_button.pack()

        self.video_folder_label = Label(content_frame, text="Video Folder:")
        self.video_folder_label.pack()
        self.video_folder_edit = Entry(content_frame, width=100)
        self.video_folder_edit.pack()
        self.video_folder_button = Button(content_frame, text="Browse Folders", command=self.browse_video_folder)
        self.video_folder_button.pack()

        self.min_size_threshold_label = Label(content_frame, text="Minimum Size Threshold:")
        self.min_size_threshold_label.pack()
        self.min_size_threshold_edit = Entry(content_frame, width=50)
        self.min_size_threshold_edit.pack()

        self.global_threshold_label = Label(content_frame, text="Global Threshold:")
        self.global_threshold_label.pack()
        self.global_threshold_edit = Entry(content_frame, width=50)
        self.global_threshold_edit.pack()

        self.percentage_threshold_label = Label(content_frame, text="Percentage Threshold:")
        self.percentage_threshold_label.pack()
        self.percentage_threshold_edit = Entry(content_frame, width=50)
        self.percentage_threshold_edit.pack()

        self.dilation_kernel_label = Label(content_frame, text="Dilation Kernel:")
        self.dilation_kernel_label.pack()
        self.dilation_kernel_edit = Entry(content_frame, width=50)
        self.dilation_kernel_edit.pack()

        self.oaf_check = IntVar()
        self.set_roi_check = IntVar()
        self.name_stamp_check = IntVar()
        self.oaf_check_button = Checkbutton(content_frame, text="Override Actigraphy Files", variable=self.oaf_check)
        self.oaf_check_button.pack()
        self.set_roi_check_button = Checkbutton(content_frame, text="Set Region of Interest (ROI)", variable=self.set_roi_check)
        self.set_roi_check_button.pack()
        self.name_stamp_check_button = Checkbutton(content_frame, text="Use Name Stamp", variable=self.name_stamp_check)
        self.name_stamp_check_button.pack()
        self.name_stamp_check_button.select()

        self.start_button = Button(content_frame, text="Start Actigraphy", command=self.start_actigraphy)
        self.start_button.pack()

        self.progress_bar = ttk.Progressbar(content_frame, orient=HORIZONTAL, length=500, mode='determinate')
        self.progress_bar.pack(pady=20)

        self.btn_most_movement = Button(content_frame, text="Most Movement", command=lambda: self.set_defaults(self.settings_most_movement))
        self.btn_most_movement.pack()
        self.btn_medium_movement = Button(content_frame, text="Medium Movement", command=lambda: self.set_defaults(self.settings_medium_movement))
        self.btn_medium_movement.pack()
        self.btn_only_large_movement = Button(content_frame, text="Only Large Movement", command=lambda: self.set_defaults(self.settings_only_large_movement))
        self.btn_only_large_movement.pack()

        self.output_directory_label = Label(content_frame, text="Output CSV File:")
        self.output_directory_label.pack()
        self.output_directory_edit = Entry(content_frame, width=100)
        self.output_directory_edit.pack()
        self.output_directory_button = Button(content_frame, text="Select Output File Destination", command=self.select_output_file_destination)
        self.output_directory_button.pack()

    def set_defaults(self, settings):
        self.global_threshold_edit.delete(0, END)
        self.global_threshold_edit.insert(0, settings['global_threshold'])
        self.percentage_threshold_edit.delete(0, END)
        self.percentage_threshold_edit.insert(0, settings['percentage_threshold'])
        self.min_size_threshold_edit.delete(0, END)
        self.min_size_threshold_edit.insert(0, settings['min_size_threshold'])
        self.dilation_kernel_edit.delete(0, END)
        self.dilation_kernel_edit.insert(0, settings['dilation_kernel'])

    def select_output_file_destination(self):
        directory = filedialog.askdirectory()
        if directory:
            self.output_directory = directory
            self.output_directory_edit.delete(0, END)
            self.output_directory_edit.insert(0, directory)

    def browse_video_file(self):
        file_name = filedialog.askopenfilename(filetypes=[('MP4 files', '*.mp4')])
        self.video_file_edit.delete(0, END)
        self.video_file_edit.insert(0, file_name)

    def browse_video_folder(self):
        dir_name = filedialog.askdirectory()
        self.video_folder_edit.delete(0, END)
        self.video_folder_edit.insert(0, dir_name)

    def start_actigraphy(self):
        video_file = self.video_file_edit.get()
        video_folder = self.video_folder_edit.get()

        try:
            min_size_threshold = int(self.min_size_threshold_edit.get())
            global_threshold = int(self.global_threshold_edit.get())
            percentage_threshold = int(self.percentage_threshold_edit.get())
            dilation_kernel = int(self.dilation_kernel_edit.get())
        except ValueError as ve:
            messagebox.showwarning("Invalid Input", "Please enter valid integer values for thresholds and dilation kernel.")
            self.start_button["state"] = "normal"
            return

        oaf = self.oaf_check.get()
        set_roi = self.set_roi_check.get()
        name_stamp = self.name_stamp_check.get()

        self.actigraphy_processor.set_processing_parameters(global_threshold, min_size_threshold, percentage_threshold, dilation_kernel)
        
        self.start_button["state"] = "disabled"

        output_file_path = self.output_directory_edit.get().strip()
        if output_file_path:
            self.actigraphy_processor.output_file_path = output_file_path
        else:
            self.actigraphy_processor.output_file_path = None

        if video_file:
            self.thread = threading.Thread(target=self.actigraphy_processor.process_single_video_file, args=(
                video_file, name_stamp, set_roi, self.output_directory, self.update_progress_bar))
            self.thread.start()
        elif video_folder:
            self.thread = threading.Thread(target=self.actigraphy_processor.process_video_files, args=(
                video_folder, oaf, set_roi, name_stamp, self.output_directory, self.update_progress_bar))
            self.thread.start()
        else:
            messagebox.showwarning("Input Error", "No video file or folder has been selected.")
            self.start_button["state"] = "normal"

    def update_progress_bar(self, value):
        self.progress_bar["value"] = value
        self.root.update_idletasks()

    def on_processing_finished(self):
        self.progress_bar["value"] = 100
        messagebox.showinfo("Actigraphy Processing", "Actigraphy processing has been completed.")
        self.start_button["state"] = "normal"

class ActigraphyProcessor:
    def __init__(self):
        self.roi_pts = None
        self.output_file_path = None
        self.min_size_threshold = 0.0
        self.global_threshold = 0.0
        self.percentage_threshold = 0.0
        self.dilation_kernel = 0

    def set_processing_parameters(self, global_threshold, min_size_threshold, percentage_threshold, dilation_kernel):
        self.global_threshold = global_threshold
        self.min_size_threshold = min_size_threshold
        self.percentage_threshold = percentage_threshold
        self.dilation_kernel = dilation_kernel

    def get_nested_paths(self, root_dir):
        queue = [root_dir]
        paths = []
        while queue:
            current_dir = queue.pop(0)
            paths.append(current_dir)
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
            for mp4_file in mp4_files:
                if mp4_file[:-4] + "_actigraphy.csv" in csv_files and not oaf:
                    continue
                updated_mp4_files.append(mp4_file)
            mp4_files = updated_mp4_files
        return mp4_files

    def process_single_video_file(self, video_file, name_stamp, set_roi, output_directory, progress_callback, roi_pts=None):
        if name_stamp:
            creation_time = self._get_creation_time_from_name(video_file)
        else:
            creation_time = int(os.path.getctime(video_file) * 1000)

        cap = cv2.VideoCapture(video_file)
        prev_frame = None
        frame_number = 0

        outputfile_name = os.path.splitext(os.path.basename(video_file))[0] + "_actigraphy.csv"
        output_file_path = os.path.join(output_directory, outputfile_name) if output_directory else os.path.join(os.path.dirname(video_file), outputfile_name)
        result_rows = []

        with open(output_file_path, 'w', newline='') as output_file:
            writer = csv.writer(output_file)
            writer.writerow(['Frame', 'TimeElapsedMicros', 'RawDifference', 'RMSE','SelectedPixelDifference', 'PositTime'])

            if set_roi and self.roi_pts is None:
                self.roi_pts = self._select_roi_from_first_frame(cap)

            total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            while True:
                ret, frame = cap.read()
                if not ret:
                    break
                frame_number += 1
                elapsed_millis = cap.get(cv2.CAP_PROP_POS_MSEC)

                if set_roi and self.roi_pts:
                    frame = self._apply_roi(frame, self.roi_pts)
                if prev_frame is not None:
                    raw_diff, rmse, selected_pixel_diff = self._calculate_metrics(frame, prev_frame)
                    posix_time = int(creation_time + (elapsed_millis))
                    result_rows.append([frame_number, elapsed_millis, raw_diff, rmse, selected_pixel_diff, posix_time])
                    if len(result_rows) >= 1000:
                        writer.writerows(result_rows)
                        result_rows = []

                prev_frame = frame

                if progress_callback and frame_number % 100 == 0:
                    progress = (frame_number / total_frames) * 100
                    progress_callback(progress)

            writer.writerows(result_rows)
            cap.release()

    def process_video_files(self, video_folder, oaf, set_roi, name_stamp, output_directory, progress_callback=None):
        start_time = time.time()
        total_frames_processed = 0
        total_time_taken = 0

        nested_folders = self.get_nested_paths(video_folder)
        all_mp4_files = [
            os.path.join(folder, mp4_file)
            for folder in nested_folders
            for mp4_file in self.list_mp4_files(folder, oaf)
        ]
        total_files = len(all_mp4_files)
        files_processed = 0

        if total_files == 0:
            return

        if set_roi and not self.roi_pts and all_mp4_files:
            first_video_file = all_mp4_files[0]
            cap = cv2.VideoCapture(first_video_file)
            if cap.isOpened():
                self.roi_pts = self._select_roi_from_first_frame(cap)
                cap.release()
            else:
                return

        for mp4_file in all_mp4_files:
            file_start_time = time.time()
            self.process_single_video_file(mp4_file, name_stamp, set_roi, output_directory, None, self.roi_pts)
            file_end_time = time.time()
            total_time_taken += file_end_time - file_start_time
            files_processed += 1

            if progress_callback:
                folder_progress = int((files_processed / total_files) * 100)
                progress_callback(folder_progress)

            cap = cv2.VideoCapture(mp4_file)
            total_frames_processed += int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            cap.release()

        end_time = time.time()
        total_time_taken = end_time - start_time

        if progress_callback:
            progress_callback(100)

    def _select_roi_from_first_frame(self, cap):
        ret, frame = cap.read()
        if not ret:
            return None

        roi_pts = cv2.selectROI(frame)
        cv2.destroyAllWindows()
        return roi_pts

    def _apply_roi(self, frame, roi_pts):
        x, y, w, h = roi_pts
        return frame[int(y):int(y + h), int(x):int(x + w)]

    def _calculate_metrics(self, frame, prev_frame):
        frame_gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        prev_frame_gray = cv2.cvtColor(prev_frame, cv2.COLOR_BGR2GRAY)
        abs_diff = np.abs(frame_gray.astype(np.float32) - prev_frame_gray.astype(np.float32))
        raw_diff = np.sum(abs_diff)
        rmse = np.sqrt(np.mean(abs_diff ** 2))

        prev_frame_safe = prev_frame_gray.astype(np.float32) + 1e-5
        percentage_change = np.abs((frame_gray.astype(np.float32) - prev_frame_safe) / prev_frame_safe)
        percentage_change_scaled = np.clip(percentage_change * 100, 0, 100).astype(np.uint8)
        _, abs_diff_mask = cv2.threshold(abs_diff, self.global_threshold, 255, cv2.THRESH_BINARY)
        _, percentage_change_mask = cv2.threshold(percentage_change_scaled, self.percentage_threshold, 255, cv2.THRESH_BINARY)
        abs_diff_mask = abs_diff_mask.astype(np.uint8)
        percentage_change_mask = percentage_change_mask.astype(np.uint8)
        combined_mask = cv2.bitwise_and(abs_diff_mask, percentage_change_mask)
        kernel = np.ones((self.dilation_kernel, self.dilation_kernel), np.uint8)
        dilated_mask = cv2.dilate(combined_mask, kernel, iterations=1)
        num_labels, labels, stats, _ = cv2.connectedComponentsWithStats(dilated_mask, connectivity=8)
        component_areas = stats[1:, cv2.CC_STAT_AREA]
        large_components = component_areas >= self.min_size_threshold
        filtered_mask = np.zeros_like(dilated_mask)
        filtered_mask[np.isin(labels, np.nonzero(large_components)[0] + 1)] = 255
        selected_pixel_diff = np.sum(filtered_mask)
        return raw_diff, rmse, selected_pixel_diff

    @staticmethod
    def _get_creation_time_from_name(filename):
        regex_pattern_1 = r'(\d{8}_\d{9})'
        regex_pattern_2 = r'(\d{8}_\d{6})'
        match = re.search(regex_pattern_1, os.path.basename(filename))
        if match:
            date_time_str = match.group(1)
            date_time_format = '%Y%m%d_%H%M%S%f'
            date_time_obj = datetime.strptime(date_time_str, date_time_format)
            posix_timestamp_ms = int(date_time_obj.timestamp() * 1000)
            return posix_timestamp_ms
        else:
            match = re.search(regex_pattern_2, os.path.basename(filename))
            if match:
                date_time_str = match.group(1)
                date_time_format = '%Y%m%d_%H%M%S'
                date_time_obj = datetime.strptime(date_time_str, date_time_format)
                posix_timestamp_ms = int(date_time_obj.timestamp() * 1000)
                return posix_timestamp_ms
            else:
                return int(os.path.getctime(filename) * 1000)

if __name__ == "__main__":
    root = Tk()
    actigraphy_processor = ActigraphyProcessor()
    app = ActigraphyProcessorApp(root, actigraphy_processor)
    root.mainloop()