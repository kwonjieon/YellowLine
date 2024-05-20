from django.utils import timezone
from django import forms
from .models import History, User


class SignUpForm(forms.ModelForm):
    class Meta:
        model = User
        fields = ['id', 'password', 'name', 'option', 'phoneNum']
class LoginForm(forms.Form):
    id = forms.CharField(max_length=45, label='아이디')
    password = forms.CharField(widget=forms.PasswordInput(), label='비밀번호')

class UserRelationForm(forms.Form):
    helper_id = forms.CharField(max_length=45, label='보호자 아이디')
    recipient_id = forms.CharField(max_length=45, label='피보호자 아이디')

class HistoryForm(forms.ModelForm):
    class Meta:
        model = History
        fields = ['arrival']  

    def save(self, commit=True):
        history = super().save(commit=False)
        history.time = timezone.now()  # Set the current time
        if commit:
            history.save()
        return history