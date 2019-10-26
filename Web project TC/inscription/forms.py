from django import forms
from .models import *

#définition des champs input du formulaire. Le code est généré en focntion des composants.
class intervenantForm(forms.Form):
    username = forms.CharField(
        required = True,
        widget = forms.TextInput(attrs={
            'class' : 'form-control' , 'placeholder' : 'Username' , 'id':'username'
        })
    )
    nom = forms.CharField(
        required = True, #si le champ est absolument nécessaire (changera avec les fichiers)
        widget = forms.TextInput(attrs={
            'class' : 'form-control' , 'placeholder' : 'Nom' , 'id':'nom' #placeholder permet de mettre un peu de texte dans le champ de formulaire -> disparait losqu'on clique!
        })
        #form contrôle, c'est du bootstrap, cela permet d'avoir un design préd&éfini
    )
    prenom = forms.CharField(
        required = True,
        widget = forms.TextInput(attrs={
            'class' : 'form-control' , 'placeholder' : 'prenom' , 'id':'prenom'
        })
    )
    date_naissance = forms.CharField(
        required = True,
        widget = forms.TextInput(attrs={
            'class' : 'form-control' , 'placeholder' : 'JJ/MM/AAAA' , 'id':'date_naissance'
        })
    )
    adresse = forms.CharField(
        required = True,
        widget = forms.EmailInput(attrs={
            'class' : 'form-control' , 'placeholder' : 'exemple: jojo@brorientation.com' , 'id':'adresse'
        })
    )
    password = forms.CharField(
        required = True,
        widget = forms.PasswordInput(attrs={
            'class' : 'form-control' , 'placeholder' : 'Password' , 'id':'password'
        })
    )
    password_confirmation = forms.CharField(
        required = True,
        widget = forms.PasswordInput(attrs={
            'class' : 'form-control' , 'placeholder' : 'Password confirmation' , 'id':'password_confirmation'
        })
    )
    certificat = forms.ImageField(
        required = True,
        widget = forms.FileInput(attrs={
            'class' : 'form-control' , 'placeholder' : 'certificat de scolarité' , 'id':'certificat'
        })
    )
    nomEcole = forms.CharField(
        required = True,
        widget = forms.TextInput(attrs={
            'class' : 'form-control' , 'placeholder' : 'nomEcole' , 'id':'nomEcole'
        })
    )
    type = forms.CharField(
        required = True,
        widget = forms.TextInput(attrs={
            'class' : 'form-control' , 'placeholder' : 'type' , 'id':'type'
        })
    )
class postulantForm(forms.Form):

    username = forms.CharField(
        required = True,
        widget = forms.TextInput(attrs={
            'class' : 'form-control' , 'placeholder' : 'Username' , 'id':'username'
        })
    )
    nom = forms.CharField(
        required = True, #si le champ est absolument nécessaire (changera avec les fichiers)
        widget = forms.TextInput(attrs={
            'class' : 'form-control' , 'placeholder' : 'Nom' , 'id':'nom' #placeholder permet de mettre un peu de texte dans le champ de formulaire -> disparait losqu'on clique!
        })
        #form contrôle, c'est du bootstrap, cela permet d'avoir un design préd&éfini
    )
    prenom = forms.CharField(
        required = True,
        widget = forms.TextInput(attrs={
            'class' : 'form-control' , 'placeholder' : 'prenom' , 'id':'prenom'
        })
    )
    date_naissance = forms.CharField(
        required = True,
        widget = forms.TextInput(attrs={
            'class' : 'form-control' , 'placeholder' : 'JJ/MM/AAAA' , 'id':'date_naissance'
        })
    )
    adresse = forms.CharField(
        required = True,
        widget = forms.EmailInput(attrs={
            'class' : 'form-control' , 'placeholder' : 'exemple: jojo@brorientation.com' , 'id':'adresse'
        })
    )
    password = forms.CharField(
        required = True,
        widget = forms.PasswordInput(attrs={
            'class' : 'form-control' , 'placeholder' : 'Password' , 'id':'password'
        })
    )
    password_confirmation = forms.CharField(
        required = True,
        widget = forms.PasswordInput(attrs={
            'class' : 'form-control' , 'placeholder' : 'Password confirmation' , 'id':'password_confirmation'
        })
    )
