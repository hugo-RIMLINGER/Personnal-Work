from django.contrib.auth.models import User
from django.contrib.auth.forms import UserCreationForm, UserChangeForm
from django import forms

class EditProfileForm(forms.Form):

    description = forms.CharField(
        required = True,
        widget = forms.Textarea(attrs={
            'class' : 'form-control' , 'placeholder' : 'Description' , 'id':'description'
        })
    )

    avatar = forms.ImageField(
        required = True,
        widget = forms.FileInput(attrs={
            'class' : 'form-control' , 'placeholder' : 'avatar' , 'id':'avatar'
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
    prix = forms.CharField(
        required = True,
        widget = forms.TextInput(attrs={
            'class' : 'form-control' , 'placeholder' : 'prix' , 'id':'prix'
        })
    )

class EditProfileFormPost(forms.Form):

    description = forms.CharField(
        required = True,
        widget = forms.Textarea(attrs={
            'class' : 'form-control' , 'placeholder' : 'Description' , 'id':'description'
        })
    )

    avatar = forms.ImageField(
        required = True,
        widget = forms.FileInput(attrs={
            'class' : 'form-control' , 'placeholder' : 'avatar' , 'id':'avatar'
        })
    )
