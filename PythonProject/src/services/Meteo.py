import requests
import openmeteo_requests
import requests_cache
from retry_requests import retry
"""
    ****UNE BONNE PARTIE DE CE CODE EST FOURNIE PAR https://open-meteo.com/en/docs/historical-forecast-api****
    
    On utilise :
    - requests: pour la meteo actuelle (API simple forecast)
    - openmeteo_requests: pour l'API historique
    - requests_cache + retry : pour eviter trop de requests et gerer les erreurs reseau
"""


class MeteoService:
    """
    Cette classe s'occupe de communiquer avec l'API Open-Meteo.
    Pour ce projet on restera toujours a Montreal
    """

    #Coordonnees de Montreal
    LATITUDE = 45.5017
    LONGITUDE = -73.5673

    """
    Initialisation de la requete avec : 
    - cache local (évite de refaire la même requete pendant 1h)
    - retry automatique en cas d'erreur de reseau
    """
    def __init__(self):
        cache_session = requests_cache.CachedSession('.cache', expire_after = 3600)
        retry_session = retry(cache_session, retries = 5, backoff_factor = 0.2)
        self.openmeteo = openmeteo_requests.Client(session = retry_session)

    def temperature_actuelle(self) -> float:
        """
        Retourne la temperature actuelle a Montreal en °C

        On utilise l'API forecast avec current_weather.
        """
        url = "https://historical-forecast-api.open-meteo.com/v1/forecast"

        parametres = {
            "latitude" : self.LATITUDE,
            "longitude" : self.LONGITUDE,
            "current_weather": "true",
            "timezone": "America/Toronto"
        }

        r = requests.get(url, params=parametres, timeout = 10)
        r.raise_for_status()
        donnees = r.json()

        return float(donnees["current_weather"]["temperature"])

    def temperature_historique(self, date: str) -> float:
        """
        Retourne la temperature moyenne d'une journee passee

        :param date: (format AAAA-MM-JJ)
        :return: temperature moyenne de la journee

        On utilise l'API historical-forecast.
        On demande les temperatures horaire (tempereture_2m)
        puis on calcule la moyenne sur la journee.
        """
        url = "https://historical-forecast-api.open-meteo.com/v1/forecast"

        parametres = {
            "latitude": self.LATITUDE,
            "longitude": self.LONGITUDE,
            "start_date": date,
            "end_date": date,
            "hourly": "temperature_2m",
            "timezone": "America/Toronto",
        }

        reponses = self.openmeteo.weather_api(url, params=parametres)
        response = reponses[0]

        hourly = response.Hourly()
        temps = hourly.Variables(0).ValuesAsNumpy()

        return float(temps.mean())