from django.shortcuts import redirect, render

from .models import History, User, UserRelation, UserState


from django.db.models import Max, OuterRef, Subquery
from .forms import SignUpForm, UserRelationForm
from django.contrib.auth import authenticate, login
from django.contrib import messages
from django.contrib.auth import logout
from django.contrib.auth import login
from .forms import LoginForm
from django.contrib.auth.decorators import login_required

# Create your views here.

def home(request):
    if request.user.is_authenticated:
        current_user_option = request.user.option
    else:
        current_user_option = None

    return render(request, 'home.html', {'current_user_option': current_user_option})
def signup(request):
    if request.method == 'POST':
        form = SignUpForm(request.POST)
        if form.is_valid():
            user = form.save(commit=False)
            password = form.cleaned_data['password']
            user.set_password(password)  # 비밀번호를 해쉬값으로 변경
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
            if user is not None:     # 로그인 성공 시 
                login(request, user)
                return redirect('home')
            else: #로그인 실패 시
                messages.error(request, '아이디 또는 비밀번호가 올바르지 않습니다.')
    else:
        print("3")
        form = LoginForm()
    return render(request, 'login.html', {'form': form})
def user_logout(request):
    logout(request)
    return redirect('home')  # 로그아웃 후 이동할 URL

@login_required#로그인되어있어야함
def relations_view(request):
    # 최신 UserState를 가져오기 위해 Subquery를 사용
    latest_user_state = UserState.objects.filter(
        user_id=OuterRef('pk')
    ).order_by('-time').values('state')[:1]

    # 최신 UserState를 가진 User와 UserRelation 데이터 가져오기
    users_with_latest_state = User.objects.filter(
        id__in=UserRelation.objects.values('recipient_id')
    ).annotate(
        latest_state=Subquery(latest_user_state)
    )

    # 결과 데이터 구성
    results = []
    for user in users_with_latest_state:
        results.append({
            'id': user.id,
            'name': user.name,
            'phoneNum': user.phoneNum,
            'state': user.latest_state
        })

    return render(request, 'relations.html', {'results': results})

def makeRelations(request):
    if request.method == 'POST':
        form = UserRelationForm(request.POST)
        if form.is_valid():
            helper_id = form.cleaned_data['helper_id']
            recipient_id = form.cleaned_data['recipient_id']
            # UserRelation 테이블에 데이터 추가
            UserRelation.objects.create(helper_id=helper_id, recipient_id=recipient_id)
            return redirect('relations_url')  # 데이터 추가 후 리다이렉션
    else:
        form = UserRelationForm()
    
    return render(request, 'makerelations.html', {'form': form})


@login_required
def recentSearch(request):
    # 현재 로그인된 사용자 아이디를 가져옴
    current_user_id = request.user.id
    
    # History 테이블에서 현재 로그인된 사용자와 관련된 데이터 가져오기
    user_history = History.objects.filter(user_id=current_user_id).order_by('-historyNum')[:10]
    
    return render(request, 'recent_search.html', {'user_history': user_history})