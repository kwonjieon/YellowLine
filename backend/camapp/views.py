import io

from PIL import Image
from channels.generic.websocket import AsyncJsonWebsocketConsumer
from django.core.files.uploadedfile import InMemoryUploadedFile
# Create your views here.
import json
from django.http import HttpResponse, FileResponse
from django.shortcuts import render
from django.views.decorators.csrf import csrf_exempt
from rest_framework.decorators import api_view
from rest_framework.response import Response

from camapp.forms import ImagePostForm


@api_view(['GET'])
def apiOverview(request):
    api_urls = {
        'send image': '/yl/img  [POST]',
    }
    return Response(api_urls)


def testIndex(request):
    return HttpResponse("Hello World!")


import socket


@csrf_exempt
def reqImageFile(request):
    # last_datetime = datetime.now()
    if request.method == 'POST':
        form = ImagePostForm(request.POST, request.FILES)
        if form.is_valid():
            image_title = form.cleaned_data['title']
            image_file = form.cleaned_data['image']
            # print(image_file)
            # image_bytes = image_file.read()
            # image = Image.open(image_io).convert("RGB")
            # image.save(image_io, 'JPEG', quality=50)
            # image_io.seek(0)
            # product = form.save(commit=False)
            # product.save()

            # print(product)
            # print(datetime.now() - last_datetime)
            # last_datetime = datetime.now()

            # in_memory_uploaded_file = InMemoryUploadedFile(
            #     # file= image_file
            #     file=image_io,
            #     field_name='image',
            #     name=image_file.name,
            #     content_type='image/jpeg',
            #     # size=image_file.size,
            #     size=image_io.tell(),
            #     charset=None,
            # )
        response = HttpResponse(image_file, content_type='image/jpeg')
        # response = HttpResponse(image_io, content_type='image/jpeg')
        response['Content-Disposition'] = f'attachment; filename="{image_title}.jpeg"'
        return response
        # response = FileResponse(image_file)
        # return response
    else:
        form = ImagePostForm()
    context = {'form': form}
    return render(request, 'cams/pictureSendForm.html', context=context)


# DRF로 RESTFUL API 통신구축

# class JPEGRenderer(renderers.BaseRenderer):
#     media_type = 'image/jpeg'
#     format = 'jpg'
#     charset = None
#     render_style = 'binary'
#
#     def render(self, data, accepted_media_type=None, renderer_context=None):
#         return data

#
# @api_view(['POST'])
# # # @renderer_classes([JPEGRenderer])
# @csrf_exempt
# def taskReqImageFile(request):
#     # parser_classes = (MultiPartParser, )
#     if request.method == 'POST':
#         # def post(self, request):
#         data = request.data.copy()
#         print("-" * 8, data)
#         now = datetime.now()
#         data['image'].name = now.strftime('%Y_%m_%d_%H:%M:%S.%f') + '.jpg'
#         # data['image'].name = data['title']+'.jpg'
#         print(data)
#         serializer = PostImageSerializer(data=data)
#
#         if serializer.is_valid():
#             print(serializer.data)
#             return Response(serializer.data, status=status.HTTP_200_OK)
#         else:
#             return Response('invalid request', status=status.HTTP_400_BAD_REQUEST)
#
#
# class PostViewSet(viewsets.ModelViewSet):
#     queryset = Post.objects.all()
#     serializer_class = PostImageSerializer


"""
https://freekim.tistory.com/8 
"""
