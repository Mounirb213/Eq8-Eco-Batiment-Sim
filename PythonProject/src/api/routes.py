import copy

from flask import Blueprint, jsonify, request

from models.Batiment import Batiment
from physique.CalculThermique import CalculThermique
from services.CalculCout import CalculCout
from services.Meteo import MeteoService
from datetime import datetime

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

def lire_nb_occupants(data):
    valeur = data.get("nb_occupants", 1)

    try:
        valeur = int(valeur)
    except (TypeError, ValueError):
        return 1

    if valeur < 1:
        return 1

    return valeur

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

def obtenir_annee_pour_cout_annuel(date_meteo):
    """
    Détermine l'année utilisée pour le calcul annuel.

    Si la météo est actuelle, on utilise la dernière année complète.
    Exemple : si on est en 2026, on utilise 2025.

    Si une date historique est choisie, on utilise l'année de cette date.
    """
    derniere_annee_complete = datetime.now().year - 1

    if date_meteo == "current":
        return derniere_annee_complete

    try:
        annee = int(str(date_meteo)[0:4])
    except (TypeError, ValueError):
        return derniere_annee_complete

    if annee > derniere_annee_complete:
        return derniere_annee_complete

    return annee


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
    heures_chauffage_par_an,
    nb_occupants,
    temperatures_annuelles
):
    """
    Calcule :
    - les pertes instantanées pour la thermographie
    - le vrai coût annuel avec les températures de toute l'année
    """
    batiment = Batiment(composantes)

    calcul_thermique = CalculThermique(
        batiment=batiment,
        temperature_interieure=temperature_interieure,
        temperature_exterieure=temperature_exterieure
    )

    resultats_thermiques = calcul_thermique.calculer()

    besoin_thermique_annuel_kwh = calcul_thermique.calculer_besoin_thermique_annuel_kwh(
        temperatures_annuelles
    )

    calcul_cout = CalculCout(
        perte_totale_watts=resultats_thermiques["total"],
        type_chauffage=type_chauffage,
        heures_chauffage_par_an=heures_chauffage_par_an,
        nb_occupants=nb_occupants,
        besoin_thermique_annuel_kwh=besoin_thermique_annuel_kwh
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
        nb_occupants = lire_nb_occupants(data)
        heures_chauffage_par_an = lire_heures_chauffage_par_an(data)
        date_meteo = lire_date_meteo(data)

        temperature_exterieure = obtenir_temperature_exterieure(date_meteo)

        annee_cout_annuel = obtenir_annee_pour_cout_annuel(date_meteo)

        temperatures_annuelles = meteo_service.temperatures_moyennes_journalieres_annee(
            annee_cout_annuel
        )

        # 1. Simulation actuelle avec l'isolation choisie dans Godot
        batiment, resultats_thermiques, resultats_cout = calculer_simulation_complete(
            composantes=composantes_recues,
            temperature_interieure=temperature_interieure,
            temperature_exterieure=temperature_exterieure,
            type_chauffage=type_chauffage,
            heures_chauffage_par_an=heures_chauffage_par_an,
            nb_occupants=nb_occupants,
            temperatures_annuelles = temperatures_annuelles
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
            heures_chauffage_par_an=heures_chauffage_par_an,
            nb_occupants=nb_occupants,
            temperatures_annuelles=temperatures_annuelles
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
                "nb_occupants": nb_occupants,
                "heures_chauffage_par_an": heures_chauffage_par_an,
                "annee_cout_annuel": annee_cout_annuel,
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