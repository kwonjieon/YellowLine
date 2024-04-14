import json

from channels.consumer import SyncConsumer
from channels.generic.websocket import AsyncJsonWebsocketConsumer

# class MyConsumer(AsyncJsonWebsocketConsumer):
#     async def connect(self):
#         await self.accept()
#
#     async def disconnect(self, close_code):
#         pass
#
#     async def receive_json(self, content, **kwargs):
#         response = {
#             'message': 'Hello, world!'
#         }
#         await self.send_json(response)
from channels.generic.websocket import WebsocketConsumer


class MyConsumer(WebsocketConsumer):
    def connect(self):
        self.accept()

    def disconnect(self, code):
        pass

    def receive(self, text_data=None, bytes_data=None):
        if bytes_data:
            self.send(bytes_data = bytes_data)
        # text_data_json = json.loads(text_data)
        # image_batch = text_data_json['images']

        # # 배치 안의 각 이미지를 처리
        # for image_data in image_batch:
        #     # result = process_image(image_data)  # 이미지를 처리하는 함수
        #     self.send(text_data=json.dumps({
        #         'result': image_data
        #     }))


"""
https://clouddevs.com/django/real-time-analytics/

"""
