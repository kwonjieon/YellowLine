from django.db import models

# Create your models here.

class User(models.Model):
    id = models.CharField(max_length=45, primary_key=True)
    password = models.CharField(max_length=45)
    name = models.CharField(max_length=45)
    option_choices = [('Protector', '보호자'), ('Protected', '피보호자')]
    option = models.CharField(max_length=45, choices=option_choices)
    phoneNum = models.CharField(max_length=45)
    
    def __self__(self):
        return self.id

class UserState(models.Model):
    userStateNum = models.AutoField(primary_key=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    state_choices = [('Offline', '오프라인'), ('Walking', '도보'), ('Navigation', '네비게이션')]
    state = models.CharField(max_length=45, choices=state_choices)

    def __self__(self):
        return self.userStateNum

class History(models.Model):
    historyNum = models.AutoField(primary_key=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    departure = models.CharField(max_length=45)
    arrival = models.CharField(max_length=45)

    def __self__(self):
        return self.historyNum
    
class UserRelation(models.Model):
    userRelationNum = models.AutoField(primary_key=True)
    helper = models.ForeignKey(User, on_delete=models.CASCADE, related_name='helper_set')
    recipient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='recipient_set')

    def __self__(self):
        return self.userRelationNum