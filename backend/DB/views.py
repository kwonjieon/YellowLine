from django.shortcuts import redirect, render

from .models import UserState

from .forms import SignUpForm
from django.contrib.auth import authenticate, login
from django.contrib import messages
from django.contrib.auth import logout
from django.contrib.auth.forms import UserCreationForm
from django.contrib.auth import login
from django.contrib.auth.forms import UserCreationForm, AuthenticationForm
from .forms import LoginForm
# Create your views here.
def home(request):
    return render(request,'home.html')

def signup(request):
    if request.method == 'POST':
        form = SignUpForm(request.POST)
        if form.is_valid():
            user = form.save(commit=False)
            password = form.cleaned_data['password']
            user.set_password(password)  # 비밀번호를 안전하게 설정
            user.save()  # 회원가입 폼을 저장하고 생성된 사용자를 가져옴
            UserState.objects.create(user_id=user.id, state='Offline')#회원의 기본상태를 오프라인으로 설정
            return redirect('home')  #다시 회원가입 화면으로
    else:
        form=SignUpForm()
    return render(request,'signup.html',{'form':form})# 회원가입에 user폼넣어줌

def user_login(request):
    if request.method == 'POST':
        form = LoginForm(request.POST)
        if form.is_valid():
            user_id = form.cleaned_data['id']
            password = form.cleaned_data['password']
            user = authenticate(request, id=user_id, password=password)
            print("실행")
            if user is not None:
                login(request, user)
                # 로그인 성공 시 리디렉션할 URL 설정
                print("1")
                return redirect('home')
            else:
                # 로그인 실패 시 메시지 표시
                print("2")
                messages.error(request, '아이디 또는 비밀번호가 올바르지 않습니다.')
    else:
        print("3")
        form = LoginForm()
    return render(request, 'login.html', {'form': form})
def user_logout(request):
    logout(request)
    return redirect('home')  # 로그아웃 후 이동할 URL