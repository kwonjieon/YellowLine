
from django import forms

from camapp.models import Post


class ImagePostForm(forms.ModelForm):
    class Meta:
        model = Post
        fields = ['title', 'image']
        # labels = {
        #     'image': 'camera image',
        # }
