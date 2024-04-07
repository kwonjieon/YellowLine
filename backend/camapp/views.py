from datetime import datetime
from io import BytesIO

from django.core.files.uploadedfile import InMemoryUploadedFile
# Create your views here.
from django.http import HttpResponse
from django.http import JsonResponse
from django.shortcuts import render
from django.views.decorators.csrf import csrf_exempt
from rest_framework import status, viewsets
from rest_framework.decorators import api_view
from rest_framework.response import Response

from camapp.forms import ImagePostForm
from camapp.models import Post
from camapp.serializers import PostImageSerializer


@api_view(['GET'])
def apiOverview(request):
    api_urls = {
        'send image': '/yl/img  [POST]',
    }
    return Response(api_urls)


def testIndex(request):
    return HttpResponse("Hello World!")


# @api_view(['GET', 'POST'])
@csrf_exempt
def reqImageFile(request):
    last_datetime = datetime.now()
    count = 0
    if request.method == 'POST':
        form = ImagePostForm(request.POST, request.FILES)
        if form.is_valid():
            # form.files.get('id_image').name = form.files.get('id_title')+".jpg"
            image_title = form.cleaned_data['title']
            image_file = form.cleaned_data['image']
            product = form.save(commit=False)
            # product.save()
            print(product)
            print(datetime.now() - last_datetime)
            last_datetime = datetime.now()

            in_memory_uploaded_file = InMemoryUploadedFile(
                file=BytesIO(image_file.read()),
                field_name=None,
                name=image_file.name,
                content_type=image_file.content_type,
                size=image_file.size,
                charset=image_file.charset,
            )
        response = HttpResponse(in_memory_uploaded_file, content_type='image/jpeg')
        response['Content-Disposition'] = f'attachment; filename="{image_title}.jpg"'
        return response
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