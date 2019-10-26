from django.http import HttpResponse
from django.shortcuts import render,redirect

def home(request):
    return render(request,'ecole/ecole.html')
