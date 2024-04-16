from io import BytesIO

from PIL.Image import Image
from django.core.files.uploadedfile import InMemoryUploadedFile
from django.db import models
import sys


class Post(models.Model):
    # created = models.DateTimeField(auto_now_add=True)
    title = models.CharField(max_length=200)
    # modify_date = models.DateTimeField(null=True, blank=True)
    image = models.ImageField(null=False)

#     def convert_image(self, *args, **kwargs):
#         image_converted = convert_test(self.image)
#         self.image_converted = InMemoryUploadedFile(file=image_converted,
#                                                     field_name="ImageField",
#                                                     name=self.image.name,
#                                                     content_type='image/jpeg',
#                                                     size=sys.getsizeof(image_converted),
#                                                     charset=None)
#
#
# def convert_test(img):
#     img = Image.open(img)
#     img = img.convert('RGB')
#     img = img.resize((100, 100), Image.ANTIALIAS)
#     return image_to_bytes(img)
#
#
# def image_to_bytes(img):
#     output = BytesIO()
#     img.save(output, format='JPEG', quality=95)
#     output.seek(0)
#     return output
