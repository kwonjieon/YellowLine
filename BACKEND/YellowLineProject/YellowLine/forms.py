
from django import forms

from YellowLine.models import Post


class ImagePostForm(forms.ModelForm):
    class Meta:
        model = Post
        fields = ['image']
        labels = {
            'image': 'camera image',
        }
