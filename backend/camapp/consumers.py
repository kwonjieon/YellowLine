import json

from channels.consumer import SyncConsumer
from channels.generic.websocket import AsyncJsonWebsocketConsumer
from channels.generic.websocket import WebsocketConsumer

"""
Consumer == views라고 생각하면 됩니다.

MyConsumer : image를 받고 보내는데 사용할 consumer 
YLConsumer : WebRTC를 위해 signaling을 담당할 consumer
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
    print(str(clientId))
    return "YLParent01"


class YLConsumer(WebsocketConsumer):
    def connect(self):
        self.accept()

    def disconnect(self, code):
        pass

    def receive(self, text_data=None, bytes_data=None):
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

            print(text_data_json)
            print(f'=> {connected_users}')
            message = text_data_json
            self.send(text_data=json.dumps({
                'connected': message,
            }))


"""
https://clouddevs.com/django/real-time-analytics/

"""
