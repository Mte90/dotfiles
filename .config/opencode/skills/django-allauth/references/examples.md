# Examples

Loaded on demand from the main django-allauth skill.

### Custom Signup Form

```python
# forms.py
from allauth.account.forms import SignupForm

class CustomSignupForm(SignupForm):
    first_name = forms.CharField(max_length=30)
    last_name = forms.CharField(max_length=30)
    
    def save(self, request):
        user = super().save(request)
        user.first_name = self.cleaned_data['first_name']
        user.last_name = self.cleaned_data['last_name']
        user.save()
        return user

# views.py
from allauth.account.views import SignupView
from .forms import CustomSignupForm

class CustomSignupView(SignupView):
    form_class = CustomSignupForm

# urls.py
path('accounts/signup/', CustomSignupView.as_view(), name='account_signup')
```

### Require Verified Email

```python
# myapp/middleware.py
from django.shortcuts import redirect
from allauth.account.models import EmailAddress

def verified_email_required(get_response):
    def middleware(request):
        if request.user.is_authenticated:
            email = EmailAddress.objects.filter(
                user=request.user,
                verified=True
            ).exists()
            if not email:
                return redirect('/accounts/verify-email/')
        return get_response(request)
    return middleware

# settings.py
MIDDLEWARE += ['myapp.middleware.verified_email_required']
```