import copy

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
    valeur = data.get("temperature_interieure", data.get("temp_interieur_c", 21.0))

    try:
        return float(valeur)
    except (TypeError, ValueError):
        return 21.0

def lire_type_chauffage(data):
    return str(data.get("type_chauffage", "chauffage_electrique")).strip().lower()

def lire_heures_chauffage_par_an(data):
    valeur = data.get("heures_chauffage_par_an", 4320)

    try:
        return float(valeur)
    except (TypeError, ValueError):
        return 4320

def lire_date_meteo(data):
    date = data.get("date", "current")

    if date is None:
        return "current"

    date = str(date).strip()

    if date == "":
        return "current"

    return date

def lire_composantes(data):
    if isinstance(data, list):
        return data

    composantes = data.get("composantes", [])

    if isinstance(composantes, list):
        return composantes

    return []

def obtenir_temperature_exterieure(date):
    if date == "current":
        return meteo_service.temperature_actuelle()

    return meteo_service.temperature_historique(date)


def copier_composantes_avec_isolation(composantes, isolation_type):
    """
    Crée une copie des composantes et force un type d'isolation.

    Exemple :
    - toutes les composantes deviennent isolation_type = "moyenne"
    """
    composantes_copiees = copy.deepcopy(composantes)

    for composante in composantes_copiees:
        composante["isolation_type"] = isolation_type

    return composantes_copiees


def calculer_simulation_complete(
    composantes,
    temperature_interieure,
    temperature_exterieure,
    type_chauffage,
    heures_chauffage_par_an
):
    """
    Calcule :
    - le bâtiment
    - les pertes thermiques
    - le coût annuel
    """
    batiment = Batiment(composantes)

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

    return batiment, resultats_thermiques, resultats_cout


def calculer_economies_annuelles(resultats_cout_actuel, resultats_cout_reference):
    """
    Formule :
    économies = coût moyen de référence - coût actuel

    Si coût actuel > coût moyen :
        économies négatives

    Si coût actuel < coût moyen :
        économies positives
    """
    cout_actuel = resultats_cout_actuel.get("cout_annuel", 0.0)
    cout_reference = resultats_cout_reference.get("cout_annuel", 0.0)

    economies = cout_reference - cout_actuel

    return round(economies, 2)


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

        # 1. Simulation actuelle avec l'isolation choisie dans Godot
        batiment, resultats_thermiques, resultats_cout = calculer_simulation_complete(
            composantes=composantes_recues,
            temperature_interieure=temperature_interieure,
            temperature_exterieure=temperature_exterieure,
            type_chauffage=type_chauffage,
            heures_chauffage_par_an=heures_chauffage_par_an
        )

        # 2. Simulation de référence avec isolation moyenne
        composantes_reference = copier_composantes_avec_isolation(
            composantes=composantes_recues,
            isolation_type="moyenne"
        )

        batiment_reference, resultats_thermiques_reference, resultats_cout_reference = calculer_simulation_complete(
            composantes=composantes_reference,
            temperature_interieure=temperature_interieure,
            temperature_exterieure=temperature_exterieure,
            type_chauffage=type_chauffage,
            heures_chauffage_par_an=heures_chauffage_par_an
        )

        # 3. Économies par rapport au coût moyen de référence
        economies_annuelles = calculer_economies_annuelles(
            resultats_cout_actuel=resultats_cout,
            resultats_cout_reference=resultats_cout_reference
        )

        resultats_cout["economies_annuelles"] = economies_annuelles

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
            "resultats_cout": resultats_cout,
            "reference_moyenne": {
                "description": "Même bâtiment avec une isolation moyenne.",
                "isolation_type": "moyenne",
                "resultats_thermiques": resultats_thermiques_reference,
                "resultats_cout": resultats_cout_reference
            }
        }

        return jsonify(reponse), 200

    except Exception as e:
        return jsonify({
            "message": "Erreur pendant la simulation.",
            "erreur": str(e)
        }), 500