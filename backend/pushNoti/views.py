import json
from django.http import JsonResponse

from django.views.decorators.csrf import csrf_exempt
from django.shortcuts import render

from DB.models import User

# Create your views here.
@csrf_exempt
def register_or_update_apns_token(request):
    if request.method == 'POST':
        data = json.loads(request.body)
        user_id = data.get('user_id')
        apns_token = data.get('apns_token')

        if not user_id or not apns_token:
            return JsonResponse({'error': 'user_id and apns_token are required.'}, status=400)

        try:
            user = User.objects.get(id=user_id)
            user.apns_token = apns_token
            user.save()
            return JsonResponse({'success': True, 'message': 'APNs token updated successfully.'})
        except User.DoesNotExist:
            return JsonResponse({'error': 'User does not exist.'}, status=404)
    else:
        return JsonResponse({'error': 'Invalid request method.'}, status=400)