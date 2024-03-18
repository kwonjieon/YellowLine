from django.shortcuts import render


# Create your views here.

def testIndex(request):
    from django.http import HttpResponse
    return HttpResponse("Hello World!")
