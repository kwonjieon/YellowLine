from rest_framework import serializers
from camapp.models import Post
from django.core.files.uploadedfile import InMemoryUploadedFile
from io import BytesIO
from PIL import Image


class PostImageSerializer(serializers.ModelSerializer):
    # image = serializers.ImageField(use_url=True)
    # title = serializers.CharField(max_length=200, required=False, allow_blank=True)
    image = serializers.ImageField(use_url=True)

    class Meta:
        model = Post
        fields = "__all__"

    # def img_resize(img: InMemoryUploadedFile) -> InMemoryUploadedFile:
    #     pil_img = Image.open(img).convert('RGBA')
    #     pil_img = pil_img.resize((1000, 1000))
    #
    #     new_img_io = BytesIO()
    #     pil_img.save(new_img_io, format='JPG')
    #     result = InMemoryUploadedFile(
    #         new_img_io, 'ImageField', img.name, 'image/jpg', new_img_io.getbuffer().nbytes, img.charset
    #     )
    #     return result
    #
    # def create(self, validated_data):
    #     # result = self.img_resize(validated_data['image'])
    #     result = self.img_resize(validated_data.FILE.get('image'))
    #     validated_data['image'] = result
    #     return super().create(validated_data)
