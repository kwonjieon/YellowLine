from django import forms
from .models import User


class SignUpForm(forms.ModelForm):
    class Meta:
        model = User
        fields = ['id', 'password', 'name', 'option', 'phoneNum']