import cv2

from learning import outimage


source = 'test_image.jpg'  # 탐지할 이미지 파일 경로
img0 = cv2.imread(source)  # BGR


img0 = outimage(img0)
# 결과 이미지 표시
cv2.imshow('YOLOv7 Detection', img0)
cv2.waitKey(0)
cv2.destroyAllWindows()