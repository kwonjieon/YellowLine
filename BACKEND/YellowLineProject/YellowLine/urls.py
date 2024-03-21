from django.urls import path

from . import views

app_name = 'yl'

urlpatterns = [
    path('', views.testIndex, name='testIndex'),
    path('img', views.reqImageFile, name='reqImageFile'),
]
