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
# from camapp.yolov7.hubconf import custom

"""
Consumer == views라고 생각하면 됩니다.

왜 MyConsumer는 sync이고 YLConsumer는 async인가?

MYConsumer : 이미지'만' 양방향 전송 (bytes_data) 
YLConsumer : signaling 을 위한 전송 (text_data) 
"""


class MyConsumer(WebsocketConsumer):
    def connect(self):
        self.accept()

    def disconnect(self, code):
        pass

    def receive(self, text_data=None, bytes_data=None):
        if bytes_data:
            current_dir = os.getcwd()
            yolov7_path = os.path.join(current_dir, "camapp/yolov7")
            yolov7_pt_path = os.path.join(yolov7_path, "croswalk_3.pt")
            sys.path.append(yolov7_path)

            """
            # model = torch.hub.load('camapp/yolov7', 'custom', path='yolov7/croswalk_3.pt', source='local')
            # # model = torch.hub.load('WongKinYiu/yolov7', 'yolov7', 'croswalk_3.pt',
            # #                        force_reload=True, trust_repo=True)

            nparr = np.frombuffer(bytes_data, np.uint8)
            img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            image_resized = cv2.resize(img, (320, 320))
            image_rgb = cv2.cvtColor(image_resized, cv2.COLOR_BGR2RGB)

            tensor_image = torch.from_numpy(image_rgb).float().div(255.0)  # Normalize [0, 255] -> [0.0, 1.0]
            tensor_image = tensor_image.permute(2, 0, 1).unsqueeze(0)  # CHW, Batch 차원 추가

            # img0 = cv2.imread(bytes_data)
            # transform = transforms.Compose([
            #     transforms.Resize(256),  # 모델에 따라 적절한 사이즈 조정 필요
            #     transforms.CenterCrop(224),  # 모델에 따라 적절한 크롭 사이즈 조정 필요
            #     transforms.ToTensor(),
            #     transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
            # ])
            # _image = Image.open(io.BytesIO(bytes_data))
            # image = transform(_image).unsqueeze(0)

            model = torch.load(yolov7_pt_path)
            print('type: ', type(model))
            print(img)
            # results = model(img)
            
            # # model = custom(path_or_model='yolov7.pt')  # custom example
            # # model.load_state_dict(loaded['model_state_dict'])
            # # model = custom(path_or_model='croswalk_3.pt')
            # print(len(bytes_data))
            #
            # # 이미지에 대한 객체 탐지 수행
            #
            # # 탐지 결과를 JSON 형식으로 변환
            # detections = results.pandas().xyxy[0].to_json(orient="records")

            # WebSocket을 통해 클라이언트에게 결과 전송
            # self.send(text_data=detections)
            # self.send(bytes_data=results)
            """
            self.send(bytes_data=bytes_data)


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
