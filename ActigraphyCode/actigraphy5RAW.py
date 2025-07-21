#!/usr/bin/env python3
# this does not include any GUI functionality. 
# meant for use on Great Lakes only, requires only a command line. Input is as follows:
# python3 actigraphy5RAW.py --video_folder '/path' --output_directory '/path' --oaf --name_stamp
# also includes multiprocessing capability, mostly for great lakes 5 cores

#!/usr/bin/env python3
import cv2
import csv
import sys
import time
import argparse
import os
import numpy as np
import re
import datetime
from datetime import datetime
from multiprocessing import Pool, Manager, Lock

class ActigraphyProcessor:
    def __init__(self, min_size_threshold=120, global_threshold=15, percentage_threshold=25, dilation_kernel=4, output_file_path=None, roi_pts=None):
        self.min_size_threshold = min_size_threshold
        self.global_threshold = global_threshold
        self.percentage_threshold = percentage_threshold
        self.dilation_kernel = dilation_kernel
        self.output_file_path = output_file_path
        self.roi_pts = roi_pts

    def list_mp4_files(self, directory_path, oaf):
        mp4_files = [f for f in os.listdir(directory_path) if f.endswith('.mp4')]
        csv_files = [f for f in os.listdir(directory_path) if f.endswith('.csv')]
        result_files = []

        if mp4_files:
            for mp4_file in mp4_files:
                if mp4_file[:-4] + "_actigraphy.csv" in csv_files:
                    if oaf:
                        print(f"Overriding existing file for {mp4_file}")
                    else:
                        print(f"Skipping {mp4_file} as actigraphy file already exists.")
                        continue
                result_files.append(mp4_file)
        else:
            print(f"No MP4 files found in {directory_path}.")
        
        return result_files

    def process_single_video_file(self, video_file, name_stamp, set_roi, output_directory, roi_pts, progress_dict, lock):
        # Determine whether to use creation time from the file name or os.path.getctime
        if name_stamp:
            print("Extracting creation time from the name.")
            creation_time = self._get_creation_time_from_name(video_file)
        else:
            print("Using the file's actual creation time.")
            creation_time = int(os.path.getctime(video_file) * 1000)

        cap = cv2.VideoCapture(video_file)
        prev_frame = None
        frame_number = 0

        # Automatically generate the output CSV file path based on the video file name
        outputfile_name = os.path.splitext(os.path.basename(video_file))[0] + "_actigraphy.csv"
        # If an output directory is provided, use it; otherwise, save next to the video file
        output_file_path = os.path.join(output_directory, outputfile_name) if output_directory else os.path.join(os.path.dirname(video_file), outputfile_name)

        result_rows = []
        with open(output_file_path, 'w', newline='') as output_file:
            writer = csv.writer(output_file)
            writer.writerow(['Frame', 'TimeElapsedMicros', 'RawDifference', 'RMSE','SelectedPixelDifference', 'PositTime'])

            # Prompt the user to select ROI if set_roi is true
            if set_roi and not roi_pts:
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
                    frame = self._apply_roi(frame, self.roi_pts)

                if prev_frame is not None:
                    raw_diff, rmse, selected_pixel_diff = self._calculate_metrics(frame, prev_frame, self.global_threshold, self.min_size_threshold, self.percentage_threshold, self.dilation_kernel)
                    posix_time = int(creation_time + elapsed_millis)
                    result_rows.append([frame_number, elapsed_millis, raw_diff, rmse, selected_pixel_diff, posix_time])
                    if len(result_rows) >= 1000:
                        writer.writerows(result_rows)
                        result_rows = []

                prev_frame = frame

            writer.writerows(result_rows)
            cap.release()
            print(f"Actigraphy processing completed for {video_file}")

        # Update the progress
        with lock:
            progress_dict[video_file] = 1
            completed_files = sum(progress_dict.values())
            total_files = len(progress_dict)
            print(f"Folder progress: {completed_files}/{total_files} files completed ({(completed_files / total_files) * 100:.2f}%)")

    def process_video_files(self, video_folder, oaf, set_roi, name_stamp, output_directory):
        nested_folders = self.get_nested_paths(video_folder)
        all_mp4_files = [
            os.path.join(folder, mp4_file)
            for folder in nested_folders
            for mp4_file in self.list_mp4_files(folder, oaf)
        ]

        if len(all_mp4_files) == 0:
            print("No video files to process.")
            return

        if set_roi and not self.roi_pts:
            first_video_file = all_mp4_files[0]
            cap = cv2.VideoCapture(first_video_file)
            if cap.isOpened():
                self.roi_pts = self._select_roi_from_first_frame(cap)
                cap.release()

        manager = Manager()
        progress_dict = manager.dict({file: 0 for file in all_mp4_files})
        lock = manager.Lock()

        pool = Pool(processes=min(5, os.cpu_count())) # Using up to 5 cores or the number of available cores.
        pool.starmap(self.process_single_video_file, [(file, name_stamp, set_roi, output_directory, self.roi_pts, progress_dict, lock) for file in all_mp4_files])

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

    def _select_roi_from_first_frame(self, cap):
        ret, frame = cap.read()
        if not ret:
            return None
        
        roi_pts = cv2.selectROI(frame)
        cv2.destroyAllWindows()
        return roi_pts

    @staticmethod
    def _apply_roi(frame, roi_pts):
        x, y, w, h = roi_pts
        roi = frame[int(y):int(y + h), int(x):int(x + w)]
        return roi

    @staticmethod
    def _calculate_metrics(frame, prev_frame, global_threshold, min_size_threshold, percentage_threshold, dilation_kernel):
        frame_gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        prev_frame_gray = cv2.cvtColor(prev_frame, cv2.COLOR_BGR2GRAY)
        
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
        kernel = np.ones((dilation_kernel, dilation_kernel), np.uint8)
        dilated_mask = cv2.dilate(combined_mask, kernel, iterations=1)
        num_labels, labels, stats, _ = cv2.connectedComponentsWithStats(dilated_mask, connectivity=8)

        component_areas = stats[1:, cv2.CC_STAT_AREA]
        large_components = component_areas >= min_size_threshold
        filtered_mask = np.zeros_like(dilated_mask)
        filtered_mask[np.isin(labels, np.nonzero(large_components)[0] + 1)] = 255

        selected_pixel_diff = np.sum(filtered_mask)

        return raw_diff, rmse, selected_pixel_diff

    @staticmethod
    def _get_creation_time_from_name(filename):
        # This regex is designed to find "YYYYMMDD_HHMMSS"
        regex_pattern = r'(\d{8}_\d{6})'
        match = re.search(regex_pattern, os.path.basename(filename))
        
        if match:
            date_time_str = match.group(1)
            # The format string matches the new regex
            date_time_format = '%Y%m%d_%H%M%S'
            date_time_obj = datetime.strptime(date_time_str, date_time_format)
            posix_timestamp_ms = int(date_time_obj.timestamp() * 1000)
            return posix_timestamp_ms
        else:
            print(f"Failed to extract creation time from the file name: {os.path.basename(filename)}. Using file generated time instead.")
            return int(os.path.getctime(filename) * 1000)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Process actigraphy from video files.')
    parser.add_argument('--video_file', type=str, help='Path to a single video file.')
    parser.add_argument('--video_folder', type=str, help='Path to a folder containing video files.')
    parser.add_argument('--oaf', action='store_true', help='Override Actigraphy Files.')
    parser.add_argument('--output_directory', type=str, help='Output directory for CSV files.')
    parser.add_argument('--name_stamp', action='store_true', help='Generate creation time from the video file name.')

    args = parser.parse_args()

    set_roi = False

    processor = ActigraphyProcessor()

    if args.video_file:
        processor.process_single_video_file(args.video_file, args.name_stamp, set_roi, args.output_directory, None, None, None)
    elif args.video_folder:
        processor.process_video_files(args.video_folder, args.oaf, set_roi, args.name_stamp, args.output_directory)
    else:
        print("Please provide either a video file or a video folder.")