import requests

class MeteoService:
    """
    Cette classe va s'occuper de communiquer avec l'API Open-Meteo.
    Retourne une temperature extérieure.
    """

    LATITUDE = 45.5017
    LONGITUDE = -73.5673

    def temperature_actuelle(self):
        """
        :return: la temperature actuelle a Montreal
        """
        url = "https://api.open-meteo.com/v1/forecast"

        parametres = {
            "latitude" : self.LATITUDE,
            "longitude" : self.LONGITUDE,
            "meteo_actuelle": "true"

        }

        reponse = requests.get(url, params=parametres)
        reponse.raise_for_status()

        donnees = reponse.json()

        return float(donnees["meteo_actuelle"]["temperature"])

    def temperature_historique(self, date):
        """
        :param date: (format AAAA-MM-JJ)
        :return: temperature moyenne de telle journee
        """
        url = "https://archive-api.open-meteo.com/v1/archive"

        parametres = {
            "latitude": self.LATITUDE,
            "longitude": self.LONGITUDE,
            "debut_date": date,
            "fin-date": date,
            "daily": "temperature_2m_mean",
            "timezone": "America/Toronto"
        }

        reponse = requests.get(url, params=parametres)
        reponse.raise_for_status()

        donnees = reponse.json()

        return float(donnees["daily"]["temperature_2m_mean"][0])