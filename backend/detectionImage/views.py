import base64
from io import BytesIO
import tempfile
import cv2
from django.http import HttpResponse
from django.shortcuts import render
from . yolov7.learning import outimage
from detectionImage.forms import UploadFileForm
import sys
from PIL import Image

def inputImage(request):
    if request.method == 'POST':
        form = UploadFileForm(request.POST, request.FILES)
        if form.is_valid():
            file = request.FILES['file']
            temp_file = tempfile.NamedTemporaryFile(delete=False)
            with open(temp_file.name, 'wb+') as destination:
                for chunk in file.chunks():
                    destination.write(chunk)
            
            img0 = cv2.imread(temp_file.name)

            # outimage 함수에서 생성된 넘파이 배열을 PIL 이미지로 변환
            img_with_boxes = Image.fromarray(outimage(img0))

            temp_file.close()

            # PIL 이미지를 템플릿에 전달
            #return render(request, 'imageOutput.html', {'img_with_boxes': img_with_boxes})
            # PIL 이미지를 BytesIO 객체에 저장하고 Base64로 인코딩
            buffered = BytesIO()
            img_with_boxes.save(buffered, format="JPEG")
            img_str = base64.b64encode(buffered.getvalue()).decode()
            print(sys.path)
            
            # HTML 템플릿에 전달할 때 Base64로 인코딩된 이미지 데이터 전달
            return render(request, 'imageOutput.html', {'img_with_boxes': img_str})
    else:
        form = UploadFileForm()
    return render(request, 'imageUpload.html', {'form': form})


def outputImage(request):
    temp_file_path = request.session.get('temp_file_path')
    if temp_file_path:
        with open(temp_file_path, 'rb') as f:
            response = HttpResponse(f.read(), content_type="image/jpeg")
            response['Content-Disposition'] = 'inline; filename=upload.jpg'
            return response
    return HttpResponse("No image found")
