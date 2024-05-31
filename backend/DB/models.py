from django.db import models
from django.utils import timezone
# Create your models here.

from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.utils.translation import gettext_lazy as _

class UserManager(BaseUserManager):
    def create_user(self, id, password=None, **extra_fields):
        if not id:
            raise ValueError(_('The ID field must be set'))
        user = self.model(id=id, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, id, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)

        if extra_fields.get('is_staff') is not True:
            raise ValueError(_('Superuser must have is_staff=True.'))
        if extra_fields.get('is_superuser') is not True:
            raise ValueError(_('Superuser must have is_superuser=True.'))

        return self.create_user(id, password, **extra_fields)

class User(AbstractBaseUser, PermissionsMixin):
    id = models.CharField(max_length=45, primary_key=True)
    password = models.CharField(max_length=128)  # Django automatically hashes passwords
    name = models.CharField(max_length=45)
    PROTECTOR = 'Protector'
    PROTECTED = 'Protected'
    OPTION_CHOICES = [
        (PROTECTOR, '보호자'),
        (PROTECTED, '피보호자'),
    ]
    option = models.CharField(max_length=45, choices=OPTION_CHOICES)
    phoneNum = models.CharField(max_length=45)
    apns_token = models.CharField(max_length=255, blank=True, null=True)  # APNs 토큰 필드
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    objects = UserManager()

    USERNAME_FIELD = 'id'
    REQUIRED_FIELDS = ['name', 'option', 'phoneNum']

    def __str__(self):
        return self.id

class UserState(models.Model):
    userStateNum = models.AutoField(primary_key=True)
    user_id = models.CharField(max_length=45)
    state_choices = [('Offline', '오프라인'), ('Walking', '도보'), ('Navigation', '네비게이션')]
    state = models.CharField(max_length=45, choices=state_choices)
    time = models.DateTimeField(default=timezone.now)

    def __str__(self):
        return str(self.userStateNum)

class History(models.Model):
    historyNum = models.AutoField(primary_key=True)
    user_id = models.CharField(max_length=45)
    arrival = models.CharField(max_length=45)
    latitude = models.CharField(max_length=45,default='')
    longitude = models.CharField(max_length=45,default='')
    time = models.DateTimeField(default=timezone.now)
    def __str__(self):
        return str(self.historyNum)
    
class UserRelation(models.Model):
    userRelationNum = models.AutoField(primary_key=True)
    helper_id = models.CharField(max_length=45)
    recipient_id = models.CharField(max_length=45)

    def __str__(self):
        return str(self.userRelationNum)