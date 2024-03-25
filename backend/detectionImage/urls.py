

from . import views
from django.urls import path


urlpatterns = [
    path('input/',views.inputImage,name='inputImage'),
    path('output/',views.outputImage,name='outputImage'),
    
]