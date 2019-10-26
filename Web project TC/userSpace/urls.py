from django.urls import path
from . import views

urlpatterns = [
    path('profil',views.afficher_profil, name = 'afficher_profil'),
    path('edit', views.modifier_profil, name = 'modifier_profil'),
]
