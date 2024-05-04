import os
import sys

current_dir = os.getcwd()
yolov7_path = os.path.join(current_dir, "detectionImage\\yolov7")
sys.path.append(yolov7_path)