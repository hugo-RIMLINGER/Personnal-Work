from django import forms
from inscription.models import *


class ecoleForm(forms.Form):
    nomEcole = forms.CharField(
        required = True, #si le champ est absolument nécessaire (changera avec les fichiers)
        widget = forms.TextInput(attrs={
            'class' : 'form-control' , 'placeholder' : 'Ecole' , 'id':'Ecole' #placeholder permet de mettre un peu de texte dans le champ de formulaire -> disparait losqu'on clique!
        })
        #form contrôle, c'est du bootstrap, cela permet d'avoir un design préd&éfini
    )

class emailForm(forms.Form):
    adresse = forms.CharField(
        required = True,
        widget = forms.EmailInput(attrs={
            'class' : 'form-control' , 'placeholder' : 'exemple: jojo@brorientation.com' , 'id':'adresse'
        })
    )

class ContactForm(forms.Form):
    sujet = forms.CharField(max_length=100,  required=True)
    message = forms.CharField(widget=forms.Textarea, required=True)
    renvoi = forms.BooleanField(help_text="Cochez si vous souhaitez obtenir une copie du mail envoyé.", required=False)
