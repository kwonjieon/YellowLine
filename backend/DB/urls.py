

from django.urls import path
from django.contrib.auth import views as auth_views
from .views import home, signup, user_login, user_logout


urlpatterns = [
    #홈화면
    path('',home,name='home'),
    path('signup/', signup, name='signup'),  # 회원가입 페이지
    
    path('login/', user_login, name='login'),#로그인
    #로그인 커스텀모델로 인증할수있도록 옵션변경 '필'
    path('logout/', user_logout, name='logout'),
    #로그아웃
    #보호자이면 피보호자리스트 볼수있는화면

]