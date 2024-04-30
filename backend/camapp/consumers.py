import json

from channels.consumer import SyncConsumer
from channels.generic.websocket import AsyncJsonWebsocketConsumer
from channels.generic.websocket import WebsocketConsumer


class MyConsumer(WebsocketConsumer):
    def connect(self):
        self.accept()

    def disconnect(self, code):
        pass

    def receive(self, text_data=None, bytes_data=None):
        if bytes_data:
            self.send(bytes_data = bytes_data)



"""
https://clouddevs.com/django/real-time-analytics/

"""
