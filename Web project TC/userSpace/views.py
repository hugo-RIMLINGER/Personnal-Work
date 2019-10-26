from django.http import HttpResponse
from django.shortcuts import render,redirect
from inscription.models import Intervenantes, Postulants, Conversationssss
from django.contrib.auth.models import User
from .forms import EditProfileForm
from django.contrib.auth import authenticate
from .forms import *




def afficher_profil(request):
    current_user = request.user

    try:
        q = Intervenantes.objects.get(user=current_user)
        conversation = Conversationssss.objects.filter(intervenant_username=current_user)



        return render(request, 'profil.html',{'data': conversation})
    except:
        q = Postulants.objects.get(user=current_user)
        return render(request, 'profilPost.html')

def modifier_profil(request):
    current_user = request.user

    editForm = EditProfileForm(request.POST or None,request.FILES)
    try:
        editForm = EditProfileForm(request.POST or None,request.FILES)
        p = Intervenantes.objects.get(user=current_user)
        if editForm.is_valid():
            avatar = editForm.cleaned_data['avatar']
            description = editForm.cleaned_data['description']
            certificat = editForm.cleaned_data['certificat']
            nomEcole = editForm.cleaned_data['nomEcole']
            type = editForm.cleaned_data['type']
            prix = editForm.cleaned_data['prix']
            p.intervenant_avatar = avatar
            p.type = type
            p.prix = prix
            p.intervenant_nomEcole = nomEcole
            p.intervenant_certificat = certificat
            p.intervenant_description = description
            p.save()
            return render(request, 'profil.html')

        return render(request,'edit.html',locals())
    except:
        editForm = EditProfileFormPost(request.POST or None,request.FILES)
        r = Postulants.objects.get(user=current_user)
        if editForm.is_valid():
            avatar = editForm.cleaned_data['avatar']
            description = editForm.cleaned_data['description']
            r.postulant_avatar = avatar
            r.postulant_description = description
            r.save()
            return render(request, 'profilPost.html')
        return render(request,'editPost.html',locals())
