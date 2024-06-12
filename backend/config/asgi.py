"""
ASGI config for config project.

It exposes the ASGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/5.0/howto/deployment/asgi/
"""

import os
import django
from channels.auth import AuthMiddlewareStack
from channels.routing import ProtocolTypeRouter, URLRouter
from django.core.asgi import get_asgi_application
from django.urls import path, re_path

from camapp.consumers import YLConsumer

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

# application = get_asgi_application()

application = ProtocolTypeRouter({
    "http": get_asgi_application(),
    "websocket": URLRouter([
        re_path(r'yl/ws/sock/(?P<room_name>\w+)/$', YLConsumer.as_asgi())
    ])

})

"""
localhost:8001/yl/ws/sock/ = 보호자-피보호자 실시간 카메라 통신 기능을 위한 signaling server url


"""
