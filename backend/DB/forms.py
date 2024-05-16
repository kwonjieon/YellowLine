from django import forms
from .models import User


class SignUpForm(forms.ModelForm):
    class Meta:
        model = User
        fields = ['id', 'password', 'name', 'option', 'phoneNum']
class LoginForm(forms.Form):
    id = forms.CharField(max_length=45, label='아이디')
    password = forms.CharField(widget=forms.PasswordInput(), label='비밀번호')