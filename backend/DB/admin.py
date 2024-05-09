from django.contrib import admin

from .models import History, User, UserRelation, UserState

# Register your models here.
admin.site.register(User)
admin.site.register(UserState)
admin.site.register(History)
admin.site.register(UserRelation)