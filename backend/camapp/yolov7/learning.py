import cv2
import torch
import numpy as np
from models.experimental import attempt_load
from utils.datasets import letterbox
from utils.general import non_max_suppression, scale_coords
from utils.plots import plot_one_box
from utils.torch_utils import select_device
from matplotlib import colors
from sklearn.cluster import KMeans

def dominant_color(image, k=1):
    # 이미지에서 가장 빈번한 k개 색상을 추출
    data = np.reshape(image, (-1, 3))
    kmeans = KMeans(n_clusters=k, random_state=0).fit(data)
    colors = kmeans.cluster_centers_
    return colors.astype(int)

# 설정
device = select_device('cpu')  # 'cpu' 또는 'cuda'를 사용하여 디바이스 설정
weights = 'yolov7.pt'  # YOLOv7 가중치 파일 경로
source = '../image/traffic_light_red.jpeg'  # 탐지할 이미지 파일 경로
img_size = 640
conf_thres = 0.25  # 신뢰도 임계값
iou_thres = 0.45  # IOU 임계값

# 모델 로드
model = attempt_load(weights, map_location=device)
stride = int(model.stride.max())
names = model.module.names if hasattr(model, 'module') else model.names

# 이미지 로드 및 전처리
img0 = cv2.imread(source)  # BGR
assert img0 is not None, 'Image Not Found'
img = letterbox(img0, new_shape=img_size, stride=stride)[0]
img = img[:, :, ::-1].transpose(2, 0, 1)  # BGR to RGB, to 3x416x416
img = np.ascontiguousarray(img)

img = torch.from_numpy(img).to(device)
img = img.float()  # uint8 to fp16/32
img /= 255.0  # 0 - 255 to 0.0 - 1.0
if img.ndimension() == 3:
    img = img.unsqueeze(0)

# 객체 탐지
pred = model(img, augment=False)[0]
pred = non_max_suppression(pred, conf_thres, iou_thres, classes=None, agnostic=False)

# 탐지된 객체를 이미지에 그리기
for i, det in enumerate(pred):  # detections per image
    if len(det):
        # 바운딩 박스 조정
        det[:, :4] = scale_coords(img.shape[2:], det[:, :4], img0.shape).round()

        for *xyxy, conf, cls in reversed(det):
            x1, y1, x2, y2 = [int(xy) for xy in xyxy]
            roi = img0[y1:y2, x1:x2]
            color = dominant_color(roi, k=1)[0]
            if color[0] > color[1] and color[0] > color[2]:
                color_label = 'Red'
            elif color[1] > color[0] and color[1] > color[2]:
                color_label = 'Green'
            else:
                color_label = 'nothing'


            label = f'{names[int(cls)]} {conf:.2f} {color_label}'
            plot_one_box(xyxy, img0, label=label, color=(255, 0, 0), line_thickness=3)

            cv2.putText(img0, label, (int(xyxy[0]), int(xyxy[1] - 10)), cv2.FONT_HERSHEY_SIMPLEX, 0.4,
                        (255, 255, 255), 1)


# 결과 이미지 표시
cv2.imshow('YOLOv7 Detection', img0)
cv2.waitKey(0)
cv2.destroyAllWindows()
