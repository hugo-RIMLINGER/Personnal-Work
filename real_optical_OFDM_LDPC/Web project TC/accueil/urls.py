from django.urls import path
from . import views

urlpatterns = [
    path('accueilVisiteur',views.home, name = 'accueilVisiteur'),
    path('contact/', views.contact, name='contact'),
    path('help',views.help),
    path('recuperation', views.recuperation, name = 'recuperation' )

]
