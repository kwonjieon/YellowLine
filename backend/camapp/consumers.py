import json

from channels.generic.websocket import AsyncWebsocketConsumer
from channels.generic.websocket import WebsocketConsumer

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
            print(len(bytes_data))
            self.send(bytes_data=bytes_data)


connected_users = {'YLParent01': set(['YLUser03'])}


def findParents(clientId):
    print(f'child id is {str(clientId)}')
    return "YLParent01"


class YLConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.room_name = self.scope['url_route']['kwargs']['room_name']
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
            print(len(bytes_data))
            self.send(bytes_data=bytes_data)
        else:
            text_data_json = json.loads(text_data)
            parentId = findParents(text_data_json['clientId'])
            if parentId not in connected_users:
                connected_users[parentId] = set()
                connected_users[parentId].add(text_data_json['clientId'])
            else:
                connected_users[parentId].add(text_data_json['clientId'])

            # print(text_data_json)
            # print(f'=> {connected_users}')
            message = text_data_json['message']
            userName = text_data_json['clientId']

            await self.channel_layer.group_send(
                self.room_name,
                {
                    'type': 'chat_message',
                    'message': message
                }
            )

    # group sending을 위한 method
    async def chat_message(self, event):
        print("chat_message is running!")
        message = event['message']

        await self.send(text_data=json.dumps({
            'message': message
        }))


"""
https://clouddevs.com/django/real-time-analytics/
https://channels.readthedocs.io/en/latest/topics/consumers.html channels docs
https://github.com/stasel/WebRTC-iOS/blob/main/signaling/Swift webrtc ios demo 

"""
