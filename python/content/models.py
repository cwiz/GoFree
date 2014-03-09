from django.db import models


class Country(models.Model):
    slug        = models.CharField(max_length=512, primary_key=True)
    name_ru     = models.CharField(max_length=512)
    name_en     = models.CharField(max_length=512)

    def __unicode__(self):
        return self.name_ru

    class Meta:
        ordering = ('name_ru',)


class City(models.Model):
    slug        = models.CharField(max_length=512, primary_key=True)
    name_ru     = models.CharField(max_length=512)
    name_en     = models.CharField(max_length=512)

    country     = models.ForeignKey(Country)

    # Content

    general_desription_ru   = models.TextField()
    climate_ru              = models.TextField()
    communication_ru        = models.TextField()
    emergency_ru            = models.TextField()

    poi_ru                  = models.TextField()

    plane_ru                = models.TextField()
    train_ru                = models.TextField()
    car_ru                  = models.TextField()
    bus_ru                  = models.TextField()
    city_transport_ru       = models.TextField()

    history_ru              = models.TextField()

    def __unicode__(self):
        return self.name_ru

    class Meta:
        ordering = ('name_ru',)
