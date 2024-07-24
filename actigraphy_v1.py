#!/analysis/Khan/bin/python3
import cv2
import numpy as np
import argparse
from tkinter import filedialog
import os
import tkinter as tk
import re
import datetime
import time
from datetime import datetime


class ActigraphyProcessor:
    def __init__(self):
        self.roi_pts=None
        self.pixel_threshold = 0.0
        self.erosion_area_threshold=0.0
        self.kernel_dilation=0
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

    def process_single_video_file(self, video_file, name_stamp, set_roi, roi_pts=None):
        print("\nProcessing video file: {}.".format(video_file))
        
        
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
        outputfile_name = os.path.splitext(os.path.basename(video_file))[0] + "_actigraphy.csv"
        output_file = open(os.path.join(os.path.dirname(video_file), outputfile_name), 'w')
        output_file.write('Frame,TimeElapsedMicros,RawDifference,RMSE,SelectedPixelDifference,Posixtime\n')

        if set_roi and self.roi_pts is None:
            # If set_roi is True and roi_pts is not provided, prompt the user to select ROI
            print("Please select the region of interest (ROI) in the first frame.")
            self.roi_pts = self._select_roi_from_first_frame(cap)
        

        print('Actigraphy Started')
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
                raw_diff, rmse, selected_pixel_diff = self._calculate_metrics(frame, prev_frame, float(self.pixel_threshold), float(self.erosion_area_threshold), int(self.kernel_dilation))
                # Calculate Posixtime based on creation time and elapsed time
                posix_time = int(creation_time + (elapsed_millis))

                output_file.write(f'{frame_number},{elapsed_millis},{raw_diff},{rmse},{selected_pixel_diff},{posix_time}\n')
            else:
                output_file.write(f'{1},{0},{0},{0},{0},{creation_time}\n')

            prev_frame = frame

        output_file.close()
        cap.release()
        print("Actigraphy processing completed for {}".format(video_file))
        print("*" * 75)

    def process_video_files(self, video_folder, oaf, set_roi, name_stamp):
        nested_folders = self.get_nested_paths(video_folder)
        for folder in nested_folders:
            if folder[-1] != '/':
                folder = folder + '/'

            mp4_files = self.list_mp4_files(folder,oaf)
            if mp4_files:
                print("Starting Actigraphy In the folder: {}:".format(folder))
            else:
                print("Skipping the folder {}.".format(folder))
                continue

            # Initialize roi_pts to None for the first video in the list
            

            for mp4_file in mp4_files:
                
                self.process_single_video_file(os.path.join(folder, mp4_file), name_stamp, set_roi, self.roi_pts)
                
                # Set roi_pts to the points selected in the first video for subsequent videos
                if set_roi and self.roi_pts is None:
                    roi_pts = self._select_roi_from_first_frame(
                        cv2.VideoCapture(os.path.join(folder, mp4_file))
                    )

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
    def _calculate_metrics(frame, prev_frame, pixel_threshold, erosion_area_threshold, kernel_dilation):
        # Convert frames to grayscale
        frame_gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        prev_frame_gray = cv2.cvtColor(prev_frame, cv2.COLOR_BGR2GRAY)

        # Calculate raw difference
        raw_diff = np.sum(np.abs(frame_gray - prev_frame_gray))
        rmse = np.sqrt(np.mean((frame_gray - prev_frame_gray) ** 2))

        # Create a kernel for dilation
        kernel = np.ones((kernel_dilation, kernel_dilation), np.uint8)

        # Compute the absolute difference, then dilate
        abs_diff = cv2.absdiff(frame_gray, prev_frame_gray)
        dilated_diff = cv2.dilate(abs_diff, kernel, iterations=1)

        # Apply thresholding to create a binary image
        _, binary_diff = cv2.threshold(dilated_diff,pixel_threshold, 255, cv2.THRESH_BINARY)

        # Filter small regions
        
        num_labels, labels, stats, _ = cv2.connectedComponentsWithStats(binary_diff, connectivity=8)

        # Create an image to store the filtered regions
        filtered_image = np.zeros_like(binary_diff)

        # Filter out small components
        for label in range(1, num_labels):
            if stats[label, cv2.CC_STAT_AREA] >= erosion_area_threshold:
                filtered_image[labels == label] = 255

        # Calculate selected pixel difference
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
    parser = argparse.ArgumentParser()
    parser.add_argument('--videoFile', type=str)
    parser.add_argument('--videoFolder', type=str)
    parser.add_argument('--oaf', type=bool)
    parser.add_argument('--pixelThreshold', type=int, default=30)
    parser.add_argument('--erosionThreshold', type=int, default=90)
    parser.add_argument('--kernelDilation',type =int, default=5)
    parser.add_argument('--setROI', type=bool)
    parser.add_argument('--nameStamp', type=bool, default=True)
    args = parser.parse_args()

    if args.videoFile or args.videoFolder:
        # If either videoFile or videoFolder is provided, proceed without GUI
        actigraphy_processor = ActigraphyProcessor()
        actigraphy_processor.pixel_threshold=args.pixelThreshold
        actigraphy_processor.erosion_area_threshold = args.erosionThreshold
        actigraphy_processor.kernel_dilation = args.kernelDilation

        if args.videoFile:
            actigraphy_processor.process_single_video_file(
                args.videoFile, args.nameStamp, args.setROI
            )
        elif args.videoFolder:
            actigraphy_processor.process_video_files(
                args.videoFolder, args.oaf, args.setROI, args.nameStamp
            )

        print("Program ends here")
    else:
        # Display GUI if neither videoFile nor videoFolder is provided
        root = tk.Tk()
        root.title('Actigraphy')

        # Function to start actigraphy processing
        def start_actigraphy():
            video_file = video_file_entry.get()
            video_folder = video_folder_entry.get()

            if video_file or video_folder:
                actigraphy_processor = ActigraphyProcessor()
                actigraphy_processor.pixel_threshold=pixel_threshold_entry.get()
                actigraphy_processor.erosion_area_threshold = erosion_area_threshold_entry.get()
                actigraphy_processor.kernel_dilation = kernel_dilation_entry.get()
                root.destroy()
                if video_file:
                    actigraphy_processor.process_single_video_file(
                        video_file, name_stamp_var.get(), set_roi_var.get()
                    )
                elif video_folder:
                    actigraphy_processor.process_video_files(
                        video_folder, oaf_var.get(), set_roi_var.get(), name_stamp_var.get()
                    )

                print("Program ends here")
                

        # GUI components
        video_file_label = tk.Label(root, text="Video File:")
        video_file_entry = tk.Entry(root)
        video_file_button = tk.Button(root, text="Browse Files", command=lambda: video_file_entry.insert(tk.END, filedialog.askopenfilename(filetypes=[("MP4 files", "*.mp4")])))
        
        video_folder_label = tk.Label(root, text="Video Folder:")
        video_folder_entry = tk.Entry(root)
        video_folder_button = tk.Button(root, text="Browse Folders", command=lambda: video_folder_entry.insert(tk.END, filedialog.askdirectory()))

        pixel_threshold_value = tk.IntVar()
        pixel_threshold_label = tk.Label(root, text="Pixel Threshold:")
        pixel_threshold_entry = tk.Entry(root,textvariable=pixel_threshold_value)
        pixel_threshold_value.set(30)

        erosion_area_threshold_value = tk.IntVar()
        erosion_area_threshold_label = tk.Label(root, text="Erosion Area Threshold:")
        erosion_area_threshold_entry = tk.Entry(root,textvariable=erosion_area_threshold_value)
        erosion_area_threshold_value.set(90)

        kernel_dilation_value = tk.IntVar()
        kernel_dilation_label = tk.Label(root, text="Dilation Kernel:")
        kernel_dilation_entry = tk.Entry(root,textvariable=kernel_dilation_value)
        kernel_dilation_value.set(5)

        oaf_var = tk.BooleanVar()
        oaf_checkbutton = tk.Checkbutton(root, text="Override Actigraphy Files", variable=oaf_var)

        set_roi_var = tk.BooleanVar()
        set_roi_checkbutton = tk.Checkbutton(root, text="Set Region of Interest (ROI)", variable=set_roi_var)

        name_stamp_var = tk.BooleanVar(value=True)
        name_stamp_checkbutton = tk.Checkbutton(root, text="Use Name Stamp", variable=name_stamp_var)

        start_button = tk.Button(root, text="Start Actigraphy", command=start_actigraphy)

        # GUI layout
        video_file_label.grid(row=0, column=0, padx=5, pady=5, sticky=tk.W)
        video_file_entry.grid(row=0, column=1, padx=5, pady=5)
        video_file_button.grid(row=0, column=2, padx=5, pady=5)

        video_folder_label.grid(row=1, column=0, padx=5, pady=5, sticky=tk.W)
        video_folder_entry.grid(row=1, column=1, padx=5, pady=5)
        video_folder_button.grid(row=1, column=2, padx=5, pady=5)

        pixel_threshold_label.grid(row=2, column=0, padx=5, pady=5, sticky=tk.W)
        pixel_threshold_entry.grid(row=2, column=1, padx=5, pady=5)

        erosion_area_threshold_label.grid(row=3, column=0, padx=5, pady=5, sticky=tk.W)
        erosion_area_threshold_entry.grid(row=3, column=1, padx=5, pady=5)

        kernel_dilation_label.grid(row=4, column=0, padx=5, pady=5, sticky=tk.W)
        kernel_dilation_entry.grid(row=4, column=1, padx=5, pady=5)

        oaf_checkbutton.grid(row=5, column=0, padx=5, pady=5, columnspan=3, sticky=tk.W)
        set_roi_checkbutton.grid(row=6, column=0, padx=5, pady=5, columnspan=3, sticky=tk.W)
        name_stamp_checkbutton.grid(row=7, column=0, padx=5, pady=5, columnspan=3, sticky=tk.W)

        start_button.grid(row=8, column=0, columnspan=3, pady=10)

        # Tkinter main loop
        root.mainloop()