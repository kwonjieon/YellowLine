import json

from django.shortcuts import render, redirect
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from urllib3 import request
# Create your views here.
from django.http import HttpResponse

from camapp import models
from camapp.forms import ImagePostForm


def testIndex(request):
    return HttpResponse("Hello World!")


# @api_view(['GET', 'POST'])
@csrf_exempt
def reqImageFile(request):
    if request.method == 'POST':
        form = ImagePostForm(request.POST, request.FILES)
        if form.is_valid():
            product = form.save(commit=False)
            product.save()
            return JsonResponse(status=200, data={'ttsText':'Success'})
            # return redirect('yl:testIndex')
    else:
        form = ImagePostForm()
    context = {'form': form}
    return render(request, 'cams/pictureSendForm.html', context=context)
