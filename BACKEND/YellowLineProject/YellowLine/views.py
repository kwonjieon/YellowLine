import json

from django.shortcuts import render, redirect
from django.http import JsonResponse
from urllib3 import request
# Create your views here.
from django.http import HttpResponse

from YellowLine import models
from YellowLine.forms import ImagePostForm


def testIndex(request):
    return HttpResponse("Hello World!")


# @api_view(['GET', 'POST'])
def reqImageFile(request):
    # return HttpResponse("Hello World!")
    if request.method == 'POST':
        form = ImagePostForm(request.POST, request.FILES)
        if form.is_valid():
            product = form.save(commit=False)
            product.save()
            return redirect('yl:reqImageFile')




        # img =
        # data = json.loads(request.data)
        # return JsonResponse({'success': True})
        # return json.loads(request.FILES.get('image'))
        # return redirect('yl:testIndex')
    else:
        form = ImagePostForm()
    context = {'form': form}
    return render(request, 'pictureSendForm.html', context=context)
