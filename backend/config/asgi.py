"""
ASGI config for config project.

It exposes the ASGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/5.0/howto/deployment/asgi/
"""

import os

from channels.routing import ProtocolTypeRouter, URLRouter
from django.core.asgi import get_asgi_application
from django.urls import path

from camapp.consumers import MyConsumer

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

# application = get_asgi_application()

application = ProtocolTypeRouter({
    "http": get_asgi_application(),
    "websocket": URLRouter([
        path('yl/ws/', MyConsumer.as_asgi())
    ])
})

"""
comein > ws://localhost:8001/yl/ws/  -> {"userId": user_id, "image": image_data}
response > [ ws://localhost:8001/yl/ws/{user_id}, ws://localhost:8001/yl/ws/ ] -> {"image":image_data}


"""