from django.contrib import admin
from content.models import Country, City

class CountryAdmin(admin.ModelAdmin):
    pass

class CityAdmin(admin.ModelAdmin):
    pass

admin.site.register(Country,    CountryAdmin)
admin.site.register(City,       CityAdmin   )
