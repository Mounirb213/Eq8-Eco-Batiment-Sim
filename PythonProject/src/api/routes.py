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
    S'il n'y a rien, on utilise la météo actuelle.
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


def copier_composantes_avec_isolation(composantes, isolation_type):
    """
    Crée une copie des composantes avec un type d'isolation imposé.

    Ça permet de comparer :
    - isolation choisie par l'utilisateur
    - isolation moyenne de référence
    """
    composantes_copiees = copy.deepcopy(composantes)

    for composante in composantes_copiees:
        composante["isolation_type"] = isolation_type

    return composantes_copiees


def calculer_resultats_simulation(
    composantes,
    temperature_interieure,
    temperature_exterieure,
    type_chauffage,
    heures_chauffage_par_an
):
    """
    Calcule les résultats thermiques et les résultats de coût
    pour une liste de composantes.
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


def calculer_economies_par_rapport_moyenne(resultats_cout_actuels, resultats_cout_moyenne):
    """
    Calcule les économies par rapport à une référence moyenne.

    Formule :
    économies = coût moyen de référence - coût actuel

    Donc :
    - si le coût actuel est plus bas que la moyenne, économies positives
    - si le coût actuel est plus haut que la moyenne, économies négatives
    """
    cout_actuel = resultats_cout_actuels.get("cout_annuel", 0.0)
    cout_moyen = resultats_cout_moyenne.get("cout_annuel", 0.0)

    economies = cout_moyen - cout_actuel

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

        # Simulation avec l'isolation choisie par l'utilisateur
        batiment, resultats_thermiques, resultats_cout = calculer_resultats_simulation(
            composantes=composantes_recues,
            temperature_interieure=temperature_interieure,
            temperature_exterieure=temperature_exterieure,
            type_chauffage=type_chauffage,
            heures_chauffage_par_an=heures_chauffage_par_an
        )

        # Simulation de référence avec isolation moyenne
        composantes_moyennes = copier_composantes_avec_isolation(
            composantes=composantes_recues,
            isolation_type="moyenne"
        )

        batiment_moyen, resultats_thermiques_moyens, resultats_cout_moyens = calculer_resultats_simulation(
            composantes=composantes_moyennes,
            temperature_interieure=temperature_interieure,
            temperature_exterieure=temperature_exterieure,
            type_chauffage=type_chauffage,
            heures_chauffage_par_an=heures_chauffage_par_an
        )

        economies_annuelles = calculer_economies_par_rapport_moyenne(
            resultats_cout_actuels=resultats_cout,
            resultats_cout_moyenne=resultats_cout_moyens
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
                "description": "Référence basée sur le même bâtiment avec une isolation moyenne.",
                "isolation_type": "moyenne",
                "resultats_thermiques": resultats_thermiques_moyens,
                "resultats_cout": resultats_cout_moyens
            }
        }

        return jsonify(reponse), 200

    except Exception as e:
        return jsonify({
            "message": "Erreur pendant la simulation.",
            "erreur": str(e)
        }), 500