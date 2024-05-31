import json
from django.http import JsonResponse

from django.views.decorators.csrf import csrf_exempt
from django.shortcuts import render

from DB.models import User
from pyfcm import FCMNotification
# Create your views here.

def send_push_notification_to_protectors(recipient_ids, message_title, message_body):
    # 보호자들의 APNs 토큰 가져오기
    protectors = User.objects.filter(id__in=recipient_ids)
    apns_tokens = protectors.values_list('apns_token', flat=True)
    
    # APNs 토큰이 있는 보호자들에게만 푸시 알림 보내기
    apns_tokens = [token for token in apns_tokens if token]
    
    # FCM 서비스 초기화
    push_service = FCMNotification(api_key="AIzaSyCRI1qh3NebKAwQB5hI8wotA9tANp8BdAs")
    
    # 푸시 알림 데이터 설정
    data_message = {
        "title": message_title,
        "body": message_body,
        "sound": "default"
    }
    
    # 푸시 알림 보내기
    result = push_service.notify_multiple_devices(registration_ids=apns_tokens, data_message=data_message)
    
    # 결과 처리
    if result["success"]:
        print("푸시 알림이 성공적으로 전송되었습니다.")
    else:
        print("푸시 알림 전송에 실패했습니다:", result)

