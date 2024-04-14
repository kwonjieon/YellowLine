from django.urls import path
from . import views
from django.urls import path

from . import views

# router = routers.DefaultRouter()
# router.(r'img', views.PostViewSet)

app_name = 'yl'

urlpatterns = [
    path('', views.apiOverview, name='apiOverView'),
    path('img', views.reqImageFile, name='reqImageFile'),
    path('ws/img', views.apiOverview, name='socketForImage')
    # path('', include(router.urls)),
]

