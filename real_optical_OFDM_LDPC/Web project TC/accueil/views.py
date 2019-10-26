from django.http import HttpResponse
from django.shortcuts import render,redirect
from accueil.forms import ecoleForm, emailForm
from inscription.models import Ecoles
from inscription.models import Intervenantes
from django.core.mail import send_mail
from .forms import ContactForm
from django.template.loader import render_to_string
from django.contrib.auth.models import User
from inscription.models import Conversationssss
from datetime import *
from django.utils import timezone




def home(request):

    form = ecoleForm(request.POST or None)

    SearchCheck = False
    current_user = request.user
    afficherMessage = True
    if current_user.is_active:
        last_login = current_user.last_login
        today = datetime.now()
        if today.second > last_login.second+2 :
            afficherMessage = False
        if today.day <= last_login.day+2 :
            message_text = "Vous etes vraiment un utilisateur assidu! merci à vous!"
        elif today.month < last_date.month :
            message_text = "et bhé, on vous avez pas vu depuis longtemps!"
    #ICI
    if form.is_valid():
        #Les données sosnt envoyées a la vue sous forme de tuple avec ['clé']['valeur']
        #cleaned_data peremt de récupérer la value rde la clé passée en paramètre
        nomEcole2 = form.cleaned_data['nomEcole']
        try :
            q = Ecoles.objects.filter(ecole_nom=nomEcole2.upper())
        except q.DoesNotExist:
            q = None

        if q == None :

            SearchCheck = True

        if len(q) == 0  :

            SearchCheck = True

        else :
            #s = Intervenants.objects.filter(user)

            inter = Intervenantes.objects.filter(intervenant_nomEcole=nomEcole2.upper())


            return render(request,'accueil/Affichagerequete.html',{'data2': inter , 'data3': nomEcole2 })


    return render(request,'accueil/accueilVisiteur.html',locals())



        #ICI renvoie sur page  principale







def help(request):
    return render(request,'accueil/help.html')


def recuperation(request):
    recup = emailForm(request.POST or None)
    checkMail = True
    mailEnvoye = False
    if recup.is_valid():
        email2 = recup.cleaned_data['adresse']
        try:
            #adresse = User.objects.filter(email=email2)

            send_mail("Recuperation: mot de passe","Voici votre mot de passe : arthurarthur",'brorientation@laposte.net',["arthur.wilbrod@insa-lyon.fr"])
            mailEnvoye = True
            checkMail = True

            return render(request,'accueil/recuperation.html',locals())
        except:
            checkMail = False
    return render(request,'accueil/recuperation.html',locals())




def contact(request):
    # Construire le formulaire, soit avec les données postées,
    # soit vide si l'utilisateur accède pour la première fois
    # à la page.
    form = ContactForm(request.POST or None)
    SujetCheck = True
    MailCheck = True
    MessageCheck = False
    inter = request.GET["inter"]
    lycee = request.GET["lyceen"]
    if  len(lycee) == 0 :
        return HttpResponse("Connectez vous pour envoyer un mail")


    Uemail = User.objects.get(username=inter)
    lyceen = User.objects.get(username=lycee)
    interEmail = Uemail.email
    lyceenEmail = lyceen.email





    # Nous vérifions que les données envoyées sont valides
    # Cette méthode renvoie False s'il n'y a pas de données
    # dans le formulaire ou qu'il contient des erreurs.
    if form.is_valid():
        # Ici nous pouvons traiter les données du formulaire

        sujet = form.cleaned_data['sujet']
        message = form.cleaned_data['message']
        envoyeur = lyceenEmail
        renvoi = form.cleaned_data['renvoi']



        # Nous pourrions ici envoyer l'e-mail grâce aux données
        # que nous venons de récupérer
        envoi = True

        if  len(sujet) == 0 :
            SujetCheck=False
        if  len(message) == 0 :
            MessageCheck=False
        if  len(lyceenEmail) == 0 :
            return HttpResponse("Connectez vous pour envoyer un mail")
        else :
            msg_plain = render_to_string('accueil/email.txt', {'message': message})
            msg_html = render_to_string('accueil/email.html', {'message': message, 'envoyeur': envoyeur, 'inter': inter, 'lycee': lycee})

            Conversationssss(intervenant_username=inter,postulant_username=lycee,date=timezone.now(),message=message).save()
            #send_mail(sujet,msg_plain,'brorientation@laposte.net',[interEmail],html_message=msg_html)
            return render(request,'accueil/send.html')

    # Quoiqu'il arrive, on affiche la page du formulaire.
    return render(request,'accueil/contact.html', locals())
