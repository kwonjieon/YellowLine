from django.contrib import admin

from .models import History, User, UserRelation, UserState
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.translation import gettext_lazy as _


class UserAdmin(BaseUserAdmin):
    fieldsets = (
        (None, {'fields': ('id', 'password')}),
        (_('Personal info'), {'fields': ('name', 'phoneNum', 'option', 'apns_token')}),
        (_('Permissions'), {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('id', 'password1', 'password2', 'name', 'option', 'phoneNum'),
        }),
    )
    list_display = ('id', 'name', 'option', 'phoneNum', 'is_staff', 'is_active', 'is_superuser')
    search_fields = ('id', 'name', 'phoneNum')
    ordering = ('id',)


# Register your models here.

admin.site.register(User, UserAdmin)
admin.site.register(UserState)
admin.site.register(History)
admin.site.register(UserRelation)
