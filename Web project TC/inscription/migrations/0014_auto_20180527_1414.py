# Generated by Django 2.0 on 2018-05-27 14:14

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('inscription', '0013_auto_20180525_1447'),
    ]

    operations = [
        migrations.AddField(
            model_name='intervenantes',
            name='prix',
            field=models.CharField(default='', max_length=100),
        ),
        migrations.AddField(
            model_name='intervenantes',
            name='type',
            field=models.CharField(default='', max_length=100),
        ),
    ]
