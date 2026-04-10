from flask import Blueprint, jsonify, request

from models.Batiment import Batiment
from physique.CalculThermique import CalculThermique
from services.CalculCout import CalculCout
from services.Meteo import MeteoService

api_routes = Blueprint("api_routes", __name__)
meteo_service = MeteoService()

@api_routes.get("/health")
def health():
    return jsonify({"status": "ok"}), 200


def lire_temperature_interieure(data):
    """
    Lit la température intérieure envoyée par Godot.
    temp_interieur_c pour compatibilité.
    """
    valeur = data.get("temperature_interieure", data.get("temp_interieur_c", 21.0))

    try:
        return float(valeur)
    except (TypeError, ValueError):
        return 21.0

def lire_type_chauffage(data):
    """
    Lit le type de chauffage.
    """
    return str(data.get("type_chauffage", "chauffage_electrique")).strip().lower()

def lire_heures_chauffage_par_an(data):
    """
    Lit le nombre d'heures de chauffage par année.
    """
    valeur = data.get("heures_chauffage_par_an", 4320)

    try:
        return float(valeur)
    except (TypeError, ValueError):
        return 4320

def lire_date_meteo(data):
    """
    Lit la date pour la météo.
    Si il n'y a rien, météo actuelle.
    """
    date = data.get("date", "current")

    if date is None:
        return "current"

    date = str(date).strip()

    if date == "":
        return "current"

    return date

def lire_composantes(data):
    """
    Lit les composantes reçues de Godot.
    Listes JSON
    """
    if isinstance(data, list):
        return data

    composantes = data.get("composantes", [])

    if isinstance(composantes, list):
        return composantes

    return []

def obtenir_temperature_exterieure(date):
    """
    Retourne la température extérieure selon la date demandée.
    """
    if date == "current":
        return meteo_service.temperature_actuelle()

    return meteo_service.temperature_historique(date)



@api_routes.post("/simulate")
def simulate():
    try:
        data = request.get_json(silent=True)

        if data is None:
            return jsonify({
                "message": "Aucun JSON valide reçu."
            }), 400

        composantes_recues = lire_composantes(data)

        if len(composantes_recues) == 0:
            return jsonify({
                "message": "Aucune composante reçue pour la simulation."
            }), 400

        temperature_interieure = lire_temperature_interieure(data)
        type_chauffage = lire_type_chauffage(data)
        heures_chauffage_par_an = lire_heures_chauffage_par_an(data)
        date_meteo = lire_date_meteo(data)

        temperature_exterieure = obtenir_temperature_exterieure(date_meteo)

        batiment = Batiment(composantes_recues)

        calcul_thermique = CalculThermique(
            batiment=batiment,
            temperature_interieure=temperature_interieure,
            temperature_exterieure=temperature_exterieure
        )

        resultats_thermiques = calcul_thermique.calculer()

        calcul_cout = CalculCout(
            perte_totale_watts=resultats_thermiques["total"],
            type_chauffage=type_chauffage,
            heures_chauffage_par_an=heures_chauffage_par_an
        )

        resultats_cout = calcul_cout.calculer_resultats()

        reponse = {
            "message": "Simulation terminee avec succes",
            "batiment": batiment.to_dict(),
            "conditions": {
                "date_meteo": date_meteo,
                "temperature_interieure": temperature_interieure,
                "temperature_exterieure": temperature_exterieure,
                "type_chauffage": type_chauffage,
                "heures_chauffage_par_an": heures_chauffage_par_an
            },
            "resultats_thermiques": resultats_thermiques,
            "resultats_cout": resultats_cout
        }

        return jsonify(reponse), 200

    except Exception as e:
        return jsonify({
            "message": "Erreur pendant la simulation.",
            "erreur": str(e)
        }), 500
