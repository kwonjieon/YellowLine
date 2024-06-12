import json

from channels.generic.websocket import AsyncWebsocketConsumer

"""
Consumer == views라고 생각하면 됩니다.

왜 MyConsumer는 sync이고 YLConsumer는 async인가?

MYConsumer : 이미지'만' 양방향 전송 (bytes_data) 
YLConsumer : signaling 을 위한 전송 (text_data) 
"""

class YLConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        """
        room_name : 시각장애인 - 카메라가 시작되면 webrtc도 같이 접속해 먼저 room을 생성.
                    보호자 - webrtc연결하기 전에 서버에서 받아온 시각장애인의 id를 이용해 room_name에 접속.

        """
        self.room_name = self.scope['url_route']['kwargs']['room_name']
        print(f'channel name is {self.channel_name}')
        await self.channel_layer.group_add(
            self.room_name,
            self.channel_name
        )
        await self.accept()

    # async def websocket_disconnect(self, message):

    async def disconnect(self, code):
        await self.channel_layer.group_discard(
            self.room_name,
            self.channel_name
        )
        pass

    async def receive(self, text_data=None, bytes_data=None):

        if bytes_data:
            print('bytes data가 도착 하였습니다.')
            print(bytes_data)
            print(len(bytes_data))
            self.send(bytes_data=bytes_data)
        else:
        #     print(f'text data is {text_data}')
            self.send(text_data=text_data)
            text_data_json = json.loads(text_data)
            message = text_data_json

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
        # print("chat_message is running!")
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
