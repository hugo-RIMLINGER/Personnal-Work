from django.db import models
from django.contrib.auth.models import User
from django.core.files import File
from django.utils import timezone

class Intervenantes(models.Model):
	user = models.OneToOneField(User, on_delete=models.CASCADE)
	intervenant_date = models.CharField(max_length=10, default='')
	intervenant_avatar = models.ImageField(upload_to="photos/profil/",default='photos/profil/profile.jpg')
	intervenant_certificat = models.ImageField(upload_to="photos/certificat/")
	intervenant_description = models.TextField(default='')
	intervenant_nomEcole = models.CharField(max_length=100,default='')
	prix = models.CharField(max_length=100,default='')
	type = models.CharField(max_length=100,default='')

def __str__(self):
	return self.user


class Postulants(models.Model):
	user = models.OneToOneField(User, on_delete = models.CASCADE)
	postulant_date = models.CharField(max_length=10,default='')
	postulant_avatar = models.ImageField(upload_to='photos/',default='photos/profil/profile.jpg')
	postulant_description = models.TextField(default='')


class Ecoles(models.Model):
    ecole_nom = models.CharField(max_length=200, default = '')
    id_ecole = models.AutoField(primary_key=True)


    def __str__(self):
        return self.ecole_nom

class Conversationssss(models.Model):
	intervenant_username= models.CharField(max_length=200, default = '')
	postulant_username = models.CharField(max_length=200, default = '')
	date = models.DateTimeField(default=timezone.now,verbose_name="Date de envoie")
	message = models.TextField(default='')
