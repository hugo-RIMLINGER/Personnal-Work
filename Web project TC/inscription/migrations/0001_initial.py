# Generated by Django 2.0.5 on 2018-05-07 16:02

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='Domaine',
            fields=[
                ('id_domaine', models.AutoField(primary_key=True, serialize=False)),
                ('domaine_nom', models.CharField(max_length=100)),
            ],
        ),
        migrations.CreateModel(
            name='DomaineEcole',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('id_domaine', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='inscription.Domaine')),
            ],
        ),
        migrations.CreateModel(
            name='Ecole',
            fields=[
                ('id_ecole', models.AutoField(primary_key=True, serialize=False)),
                ('ecole_nom', models.CharField(max_length=200)),
                ('ecole_description', models.CharField(max_length=200)),
                ('lieu', models.CharField(max_length=200)),
                ('lien', models.URLField(default=0)),
            ],
        ),
        migrations.CreateModel(
            name='Intervenant',
            fields=[
                ('id_intervenant', models.AutoField(primary_key=True, serialize=False)),
                ('intervenant_nom', models.CharField(max_length=200)),
                ('intervenant_prenom', models.CharField(max_length=200)),
                ('intervenant_description', models.CharField(max_length=200)),
                ('date_naissance', models.DateField(default=0)),
                ('table_fichier', models.FileField(default=0, upload_to='')),
                ('photo_de_profil', models.ImageField(default=0, upload_to='')),
                ('adresse_mail', models.EmailField(default=0, max_length=254)),
                ('id_domaine', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='inscription.Domaine')),
                ('id_ecole', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='inscription.Ecole')),
            ],
        ),
        migrations.CreateModel(
            name='Message',
            fields=[
                ('id_message', models.AutoField(primary_key=True, serialize=False)),
                ('texte', models.CharField(max_length=1000)),
                ('date_heure', models.DateTimeField(default=0)),
                ('id_intervenant', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='inscription.Intervenant')),
            ],
        ),
        migrations.CreateModel(
            name='MotdePasse',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('pw', models.CharField(max_length=200)),
            ],
        ),
        migrations.CreateModel(
            name='Postulant',
            fields=[
                ('id_postulant', models.AutoField(primary_key=True, serialize=False)),
                ('postulant_nom', models.CharField(max_length=200)),
                ('postulant_prenom', models.CharField(max_length=200)),
                ('postulant_description', models.CharField(max_length=200)),
                ('date_naissance', models.DateField(default=0)),
                ('photo_de_profil', models.ImageField(default=0, upload_to='')),
                ('adresse_mail', models.EmailField(default=0, max_length=254)),
            ],
        ),
        migrations.AddField(
            model_name='motdepasse',
            name='id_postulant',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='inscription.Postulant'),
        ),
        migrations.AddField(
            model_name='message',
            name='id_postulant',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='inscription.Postulant'),
        ),
        migrations.AddField(
            model_name='domaineecole',
            name='id_ecole',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='inscription.Ecole'),
        ),
    ]
