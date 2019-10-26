from django.shortcuts import render
from .forms import *
from django.http import HttpResponse
from django.shortcuts import redirect
from inscription.models import Intervenantes, Postulants
from django.contrib.auth.models import User
from django.contrib.auth import authenticate,login

def home(request):
    return render(request,"inscription/inscriptionChoice.html")

def get_intervenant_infos(request):

    form = intervenantForm(request.POST or None,request.FILES)
    inscription = False
    userCheck = None
    checkPassword = False
    usernameCheck = True
    userNameError = "form-group"
    ecoleCheck = True



    if form.is_valid():
        #Les données sosnt envoyées a la vue sous forme de tuple avec ['clé']['valeur']
        #cleaned_data peremt de récupérer la value rde la clé passée en paramètre
        username = form.cleaned_data['username']
        nom = form.cleaned_data['nom']
        prenom = form.cleaned_data['prenom']
        adresse = form.cleaned_data['adresse']
        date_naissance = form.cleaned_data['date_naissance']
        password= form.cleaned_data['password']
        certificat = form.cleaned_data['certificat']
        nomEcole = form.cleaned_data['nomEcole']
        password_confirmation = form.cleaned_data['password_confirmation']
        try:
            userCheck = User.objects.get(username=username)
        except User.DoesNotExist:
            userCheck = None

        if  userCheck == None :
             usernameCheck = True
             userNameError = "form-group"
        else :
            userNameError = "form-group has-error"
            usernameCheck = False

        testEcole = Ecoles.objects.filter(ecole_nom = nomEcole)

        if len(nomEcole) != 0 :
            testEcole = Ecoles.objects.filter(ecole_nom = nomEcole)
            if len(testEcole) != 0:
                ecoleCheck = True
            else :
                ecoleCheck = False

        if (len(password) == len(password_confirmation)) and (password in password_confirmation) :
            if len(password) <= 5 :
                checkPassword = False
                errorInformation = "le mot de passe est trop court, il doit être supérieur à 5 caractères"
            else:
                checkPassword = True
        else:
            checkPassword = False
            errorInformation = "password et password_confirmation ne correspondent pas"

        if usernameCheck == True and checkPassword == True and ecoleCheck == True :
            user = User.objects.create_user(username = username, first_name = prenom, last_name = nom, password = password, email = adresse)
            data_intervenant = Intervenantes(user = user, intervenant_date = date_naissance, intervenant_certificat = certificat,intervenant_nomEcole = nomEcole)
            data_intervenant.save()
            inscription = True
            user = authenticate(username=username, password=password)
            if user is not None and user.is_active:
                login(request, user)
                return render(request, 'accueil/accueilVisiteur.html')
    #dans tous les cas on renvoie dans la page avec les informations déjà rentrées.
    return render(request,'inscription/formulaireIntervenant.html',locals())


def create_postulant(request) :

    profile_postulant = postulantForm(request.POST or None)
    inscription = False
    if profile_postulant.is_valid():
        #Les données sosnt envoyées a la vue sous forme de tuple avec ['clé']['valeur']
        #cleaned_data peremt de récupérer la value rde la clé passée en paramètre
        username = profile_postulant.cleaned_data['username']
        nom = profile_postulant.cleaned_data['nom']
        prenom = profile_postulant.cleaned_data['prenom']
        adresse =profile_postulant.cleaned_data['adresse']
        date_naissance = profile_postulant.cleaned_data['date_naissance']
        password= profile_postulant.cleaned_data['password']
        password_confirmation = profile_postulant.cleaned_data['password_confirmation']
        inscription = True
        try:
            userCheck = User.objects.get(username=username)
        except User.DoesNotExist:
            userCheck = None

        if  userCheck == None :
             usernameCheck = True
             userNameError = "form-group"
        else :
            userNameError = "form-group has-error"
            usernameCheck = False

        if (len(password) == len(password_confirmation)) and (password in password_confirmation) :
            if len(password) <= 5 :
                checkPassword = False
                errorInformation = "le mot de passe est trop court, il doit être supérieur à 5 caractères"
            else:
                checkPassword = True
        else:
            checkPassword = False
            errorInformation = "password et password_confirmation ne correspondent pas"
        #on fait le lien avec user -> maintenant objectif : "étendre le user avec un modèle"
        if usernameCheck == True and checkPassword == True :
        #on fait le lien avec user -> maintenant objectif : "étendre le user avec un modèle"
            user = User.objects.create_user(username = username, first_name = prenom, last_name = nom, password = password, email = adresse)
            profile_postulant = Postulants(user = user, postulant_date = date_naissance)
            profile_postulant.save()
            if user is not None and user.is_active:
                login(request, user)
                return render(request, 'accueil/accueilVisiteur.html')
    #dans tous les cas on renvoie dans la page avec les informations déjà rentrées.
    return render(request,'inscription/formulairePostulant.html',locals())
