import tempfile
from django.http import HttpResponse
from django.shortcuts import redirect, render

from detectionImage.forms import UploadFileForm

# Create your views here.




def inputImage(request):
    if request.method == 'POST':
        form = UploadFileForm(request.POST, request.FILES)
        if form.is_valid():
            file = request.FILES['file']
            temp_file = tempfile.NamedTemporaryFile(delete=False)
            with open(temp_file.name, 'wb+') as destination:
                for chunk in file.chunks():
                    destination.write(chunk)
            request.session['temp_file_path'] = temp_file.name
            return redirect('outputImage')
    else:
        form = UploadFileForm()
    return render(request, 'imageUpload.html', {'form': form})

def outputImage(request):
    temp_file_path = request.session.get('temp_file_path')
    if temp_file_path:
        with open(temp_file_path, 'rb') as f:
            response = HttpResponse(f.read(), content_type="image/jpeg")
            response['Content-Disposition'] = 'inline; filename=upload.jpg'
            return response
    return HttpResponse("No image found")
