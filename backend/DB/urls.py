from django.urls import path
from django.contrib.auth import views as auth_views
from .views import DestinationArrival, current_protected_info, home, insertSearch, makeRelations, recentSearch, register_or_update_apns_token, relations_view, signup, startNavi, startWalk, user_login, user_logout


urlpatterns = [
    #홈화면
    path('',home,name='home'),
    path('signup/', signup, name='signup'),  # 회원가입 페이지
    
    path('login/', user_login, name='login'),#로그인
    path('logout/', user_logout, name='logout'),#로그아웃
    #보호자이면 피보호자리스트 볼수있는화면
    path('relations/', relations_view, name='relations_url'),
    path('makerelations/',makeRelations,name='makeRelations'),
    
    path('recent/',recentSearch,name='recent_search_url'),#최근경로
    path('routeSearch/',insertSearch,name='insertSearch'),


    path('startnavi/',startNavi,name='startNavi'),

    path('protected-info/',current_protected_info,name='protected-info'),

    path('startwalk/',startWalk,name='startWalk'),
    path('arrival/',DestinationArrival,name='DestinationArrival'),

    path('register_apns_token/', register_or_update_apns_token, name='register_apns_token'),  # APNs 토큰 등록
    

    

]