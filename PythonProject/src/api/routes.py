from flask import Blueprint, jsonify, request
from services.Meteo import MeteoService

api_routes = Blueprint("api_routes", __name__)
meteo_service = MeteoService()

@api_routes.get("/health")
def health():
    return jsonify({"status": "ok"}), 200

@api_routes.post("/simulate")
def simulate():
    #recoit un Json et renvoie une reponse Json
    data = request.get_json(silent=True) or {}

    #Valeurs par défaut
    surface_m2 = float(data.get("surface_m2", 100))
    nb_occupants = int(data.get("nb_occupants", 2))
    chauffage = str(data.get("chauffage", "electricite")).lower()
    isolation = str(data.get("isolation", "moyenne")).lower()
    date = data.get("date", "current")
    temperature_interieure = float(data.get("temp_interieur_c", 21.0))

    #Recuperation meteo
    if date == "actuelle":
        temperature_exterieure = meteo_service.temperature_actuelle()
    else:
        temperature_exterieure = meteo_service.temperature_historique(date)

    #Reponse test
    response = {
        "donnees_recues": {
            "surface_m2": surface_m2,
            "nb_occupants": nb_occupants,
            "chauffage": chauffage,
            "isolation": isolation,
            "temperature_interieure": temperature_interieure,
            "temperature_exterieure": temperature_exterieure,
            "ville": "Montreal"
        },
        "message": "Meteo Montreal recuperee avec succes"
    }

    return jsonify(response), 200
