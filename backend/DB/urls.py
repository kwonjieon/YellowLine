
from django.urls import path

from .views import signup


urlpatterns = [
    path('signup/', signup, name='signup'),  # 회원가입 페이지
    
]