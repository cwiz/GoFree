from content.models import Country, City
from django.http import HttpResponse
from django.shortcuts import render, redirect, get_object_or_404

import jsonpickle

def city(request, city_slug):

    city = get_object_or_404(City, slug=city_slug)

    return HttpResponse(json.dumps(response_data), mimetype="application/json")