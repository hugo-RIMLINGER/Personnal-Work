# Generated by Django 2.0 on 2018-05-25 14:46

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('inscription', '0011_conversationssss'),
    ]

    operations = [
        migrations.RenameField(
            model_name='conversationssss',
            old_name='postulant_date',
            new_name='date',
        ),
        migrations.RenameField(
            model_name='conversationssss',
            old_name='postulant_description',
            new_name='message',
        ),
        migrations.RemoveField(
            model_name='conversationssss',
            name='postulant_avatar',
        ),
        migrations.RemoveField(
            model_name='conversationssss',
            name='user',
        ),
        migrations.AddField(
            model_name='conversationssss',
            name='intervenant_username',
            field=models.CharField(default='', max_length=200),
        ),
        migrations.AddField(
            model_name='conversationssss',
            name='postulant_username',
            field=models.CharField(default='', max_length=200),
        ),
    ]