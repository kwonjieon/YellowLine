# Generated by Django 5.0.3 on 2024-03-21 17:28

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('camapp', '0002_remove_post_modify_date'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='post',
            name='title',
        ),
    ]
