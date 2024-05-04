import json
import io
import tempfile

import cv2
import numpy as np
import torch
import os

import sys

from PIL import Image
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.generic.websocket import WebsocketConsumer

from torchvision import transforms

from camapp.yolov7.learning import outimage

# from camapp.yolov7.hubconf import custom

"""
Consumer == views라고 생각하면 됩니다.

왜 MyConsumer는 sync이고 YLConsumer는 async인가?

MYConsumer : 이미지'만' 양방향 전송 (bytes_data) 
YLConsumer : signaling 을 위한 전송 (text_data) 
"""


class MyConsumer(WebsocketConsumer):
    def connect(self):
        current_dir = os.getcwd()
        yolov7_path = os.path.join(current_dir, "camapp/yolov7")
        sys.path.append(yolov7_path)
        self.accept()

    def disconnect(self, code):
        pass

    def receive(self, text_data=None, bytes_data=None):
        if bytes_data:
            if not isinstance(bytes_data, bytes):
                raise TypeError(f"Expected 'content' to be bytes, received: {type(bytes_data)}")
            # print(type(bytes_data)) #class<'bytes'>
            #    <class '_io.BytesIO'>
            
            # data_io = io.BytesIO(bytes_data)

            #    bytes to numpy array : <class 'numpy.ndarray'>
            decoded = cv2.imdecode(np.frombuffer(bytes_data, np.uint8), -1)
            #    이미지 처리 완료
            outimage(decoded)

            #    numpy array to 'class bytes'
            _, encode_data = cv2.imencode('.jpg', decoded)
            #    'class bytes', ndarray
            print(type(encode_data.tobytes()), type(encode_data))
            self.send(bytes_data=encode_data.tobytes())
        else:
            self.send(text_data=text_data)


connected_users = {'YLParent01': set(['YLUser03'])}


def findParents(clientId):
    print(f'child id is {str(clientId)}')
    return "YLParent01"


class YLConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.room_name = self.scope['url_route']['kwargs']['room_name']
        print(f'channel name is {self.channel_name}')
        await self.channel_layer.group_add(
            self.room_name,
            self.channel_name
        )

        await self.accept()

    async def disconnect(self, code):
        await self.channel_layer.group_discard(
            self.room_name,
            self.channel_name
        )
        # pass

    async def receive(self, text_data=None, bytes_data=None):

        if bytes_data:
            print('bytes data가 도착 하였습니다.')
            print(len(bytes_data))
            self.send(bytes_data=bytes_data)
        else:
            print(f'text data is {text_data}')
            self.send(text_data=text_data)
            text_data_json = json.loads(text_data)
            # print(f'json data is {text_data_json}')
            # parentId = findParents(text_data_json['clientId'])
            # if parentId not in connected_users:
            #     connected_users[parentId] = set()
            #     connected_users[parentId].add(text_data_json['clientId'])
            # else:
            #     connected_users[parentId].add(text_data_json['clientId'])

            # print(text_data_json)
            # print(f'=> {connected_users}')
            # message = text_data_json['message']
            message = text_data_json
            # userName = text_data_json['clientId']

            await self.channel_layer.group_send(
                self.room_name,
                {
                    'type': 'chat_message',
                    'message': message,
                    'sender_name': self.channel_name
                }
            )

    # group sending을 위한 method
    async def chat_message(self, event):
        print("chat_message is running!")
        message = event['message']

        if self.channel_name != event['sender_name']:
            await self.send(text_data=json.dumps({
                # 'type': message['type'],
                # 'sessionDescription': message['sessionDescription'],
                # 'candidate': message['candidate']
                'message': message
            }))


"""
https://clouddevs.com/django/real-time-analytics/
https://channels.readthedocs.io/en/latest/topics/consumers.html channels docs
https://github.com/stasel/WebRTC-iOS/blob/main/signaling/Swift webrtc ios demo 

"""
