from django.db import models


# Create your models here.


class Post(models.Model):
    title = models.CharField(max_length=200, default="")
    # modify_date = models.DateTimeField(null=True, blank=True)
    image = models.ImageField(default='media/default_img.jpg')
