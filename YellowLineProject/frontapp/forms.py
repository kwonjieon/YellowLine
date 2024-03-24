
from django import forms

from frontapp.models import Post


class ImagePostForm(forms.ModelForm):
    class Meta:
        model = Post
        fields = ['image']
        labels = {
            'image': 'camera image',
        }
