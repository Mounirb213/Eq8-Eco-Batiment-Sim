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

    def temperatures_moyennes_journalieres_annee(self, annee: int):
        """
        Retourne les températures moyennes de chaque jour d'une année à Montréal.

        Exemple :
        [
            -7.5, -8.1, -4.2, ...
        ]

        Ces températures servent au calcul annuel réaliste du chauffage.
        """
        url = "https://historical-forecast-api.open-meteo.com/v1/forecast"

        date_debut = f"{annee}-01-01"
        date_fin = f"{annee}-12-31"

        parametres = {
            "latitude": self.LATITUDE,
            "longitude": self.LONGITUDE,
            "start_date": date_debut,
            "end_date": date_fin,
            "daily": "temperature_2m_mean",
            "timezone": "America/Toronto",
        }

        try:
            reponses = self.openmeteo.weather_api(url, params=parametres)
            response = reponses[0]

            daily = response.Daily()
            temperatures = daily.Variables(0).ValuesAsNumpy()

            return [float(temperature) for temperature in temperatures]

        except Exception:
            return self.temperatures_reference_montreal()

    def temperatures_reference_montreal(self):
        """
        Températures mensuelles approximatives utilisées en secours
        si l'API météo annuelle ne répond pas.

        Ce n'est pas parfait, mais ça évite que le backend plante.
        """
        temperatures_par_mois = {
            1: -7.0,
            2: -6.0,
            3: -1.0,
            4: 6.0,
            5: 13.0,
            6: 18.0,
            7: 21.0,
            8: 20.0,
            9: 16.0,
            10: 9.0,
            11: 3.0,
            12: -4.0
        }

        jours_par_mois = {
            1: 31,
            2: 28,
            3: 31,
            4: 30,
            5: 31,
            6: 30,
            7: 31,
            8: 31,
            9: 30,
            10: 31,
            11: 30,
            12: 31
        }

        temperatures = []

        for mois in range(1, 13):
            temperature = temperatures_par_mois[mois]
            nombre_jours = jours_par_mois[mois]

            for _ in range(nombre_jours):
                temperatures.append(temperature)

        return temperatures