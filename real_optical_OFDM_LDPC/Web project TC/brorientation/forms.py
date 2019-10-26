from django import forms
import models

class PostulantForm(forms.Form):
    postulant_nom = forms.CharField(label='Nom',max_length=100, required=True)
    postulant_prenom = forms.CharField(label='Prénom',max_length=100, required=True)
    postulant_description = forms.CharField('Description Personelle', max_length=500)
    postulant_mail = forms.EmailField(label="Votre adesse e-mail", required=True)
    postulant_date_naissance = forms.DateTimeField(label="Date de naissance", required = True)
    postulant_photo = forms.ImageField()
    postulant_mdp = forms.CharField(max_length=32, widget=forms.PasswordInput)
    postulant_confirmation = forms.CharField(max_length=32, widget=forms.PasswordInput)

class EtudiantForm(forms.Form):
    etudiant_nom = forms.CharField(label='Nom',max_length=100, required=True)
    etudiant_prenom = forms.CharField(label='Prénom',max_length=100, required=True)
    etudiant_description = forms.CharField('Description Personelle', max_length=500)
    etudiant_mail = forms.EmailField(label="Votre adesse e-mail", required=True)
    etudiant_date_naissance = forms.DateTimeField(label="Date de naissance", required = True)
    etudiant_photo = forms.ImageField()
    etudiant_mdp = forms.CharField(max_length=32, widget=forms.PasswordInput, required = True)
    etudiant_confirmation = forms.CharField(max_length=32, widget=forms.PasswordInput, required = True)
    etudiant_fichier = forms.FileField(required = True)
    etudiant_domaine = forms.CharField(widget=forms.Select(Domaine.domaine_nom))
    etudiant_ecole = forms.CharField(widget=forms.Select(Ecole.ecole_nom))
