import copy
from datetime import datetime

from flask import Blueprint, jsonify, request

from models.Batiment import Batiment
from physique.CalculThermique import CalculThermique
from services.CalculCout import CalculCout
from services.Meteo import MeteoService


api_routes = Blueprint("api_routes", __name__)
meteo_service = MeteoService()


@api_routes.get("/health")
def etat_serveur():
    """
    Petite route simple pour vérifier si le serveur Flask fonctionne.
    """
    return jsonify({"status": "ok"}), 200


# --------------------------------------------------
# Lecture des données reçues de Godot
# --------------------------------------------------

def lire_temperature_interieure(donnees):
    """
    Lit la température intérieure envoyée par Godot.

    Si Godot n'envoie rien, on utilise 21 °C par défaut.
    """
    valeur = donnees.get("temperature_interieure", 21.0)

    try:
        return float(valeur)
    except (TypeError, ValueError):
        return 21.0


def lire_type_chauffage(donnees):
    """
    Lit le type de chauffage choisi dans Godot.
    """
    return str(donnees.get("type_chauffage", "chauffage_electrique")).strip().lower()


def lire_nb_occupants(donnees):
    """
    Lit le nombre d'occupants.

    Dans Godot, les choix vont de 1 à 5.
    """
    valeur = donnees.get("nb_occupants", 1)

    try:
        valeur = int(valeur)
    except (TypeError, ValueError):
        return 1

    if valeur < 1:
        return 1

    if valeur > 5:
        return 5

    return valeur


def lire_heures_chauffage_par_an(donnees):
    """
    Lit le nombre d'heures de chauffage par année.

    Cette valeur reste utile comme sécurité, même si le nouveau calcul annuel
    utilise aussi les températures de toute l'année.
    """
    valeur = donnees.get("heures_chauffage_par_an", 4320)

    try:
        return float(valeur)
    except (TypeError, ValueError):
        return 4320


def lire_date_meteo(donnees):
    """
    Lit la date météo.

    Si Godot envoie "current", on utilise la météo actuelle.
    Sinon, on utilise la date envoyée.
    """
    date = donnees.get("date", "current")

    if date is None:
        return "current"

    date = str(date).strip()

    if date == "":
        return "current"

    return date


def lire_composantes(donnees):
    """
    Lit les composantes envoyées par Godot.

    Normalement, Godot envoie :
    {
        "composantes": [...]
    }
    """
    composantes = donnees.get("composantes", [])

    if isinstance(composantes, list):
        return composantes

    return []


# --------------------------------------------------
# Météo
# --------------------------------------------------

def obtenir_temperature_exterieure(date_meteo):
    """
    Retourne la température extérieure utilisée pour la thermographie.

    Cette température représente le moment choisi par l'utilisateur.
    """
    if date_meteo == "current":
        return meteo_service.temperature_actuelle()

    return meteo_service.temperature_historique(date_meteo)


def obtenir_annee_pour_cout_annuel(date_meteo):
    """
    Détermine l'année utilisée pour calculer le coût annuel.

    Si l'utilisateur choisit une date en 2024, on utilise les températures
    de toute l'année 2024 pour le coût annuel.

    Si l'utilisateur choisit la météo actuelle, on utilise la dernière année complète.

    Aidé avec ChatGPT
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


# --------------------------------------------------
# Simulation
# --------------------------------------------------

def copier_composantes_avec_isolation(composantes, isolation_type):
    """
    Crée une copie des composantes et change leur isolation.

    On utilise ça pour comparer le bâtiment actuel avec une isolation moyenne.
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
    Calcule une simulation complète.

    Cette fonction fait :
    - création du bâtiment
    - calcul thermique instantané pour la thermographie
    - calcul annuel du chauffage avec les températures de l'année
    - calcul du coût annuel
    """
    batiment = Batiment(composantes)

    calcul_thermique = CalculThermique(
        batiment=batiment,
        temperature_interieure=temperature_interieure,
        temperature_exterieure=temperature_exterieure
    )

    # Résultats instantanés : utiles pour thermographie et pertes du moment.
    resultats_thermiques = calcul_thermique.calculer()

    # Résultat annuel : utilise toutes les températures de l'année.
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
    Calcule les économies par rapport à une isolation moyenne.

    Formule :
        économies = coût avec isolation moyenne - coût actuel

    Donc :
    - isolation mauvaise : économies négatives
    - isolation moyenne : environ 0
    - bonne isolation : économies positives
    """
    cout_actuel = resultats_cout_actuel.get("cout_annuel", 0.0)
    cout_reference = resultats_cout_reference.get("cout_annuel", 0.0)

    economies = cout_reference - cout_actuel

    return round(economies, 2)


# --------------------------------------------------
# Route principale utilisée par Godot
# --------------------------------------------------

@api_routes.post("/simulate")
def simuler():
    """
    Route appelée par Godot quand l'utilisateur clique sur GO.
    """
    try:
        donnees = request.get_json(silent=True)

        if donnees is None:
            return jsonify({
                "message": "Aucun JSON valide reçu."
            }), 400

        composantes_recues = lire_composantes(donnees)

        if len(composantes_recues) == 0:
            return jsonify({
                "message": "Aucune composante reçue pour la simulation."
            }), 400

        # Lecture des paramètres envoyés par Godot.
        temperature_interieure = lire_temperature_interieure(donnees)
        type_chauffage = lire_type_chauffage(donnees)
        nb_occupants = lire_nb_occupants(donnees)
        heures_chauffage_par_an = lire_heures_chauffage_par_an(donnees)
        date_meteo = lire_date_meteo(donnees)

        # Température du moment choisi. Elle sert à la thermographie.
        temperature_exterieure = obtenir_temperature_exterieure(date_meteo)

        # Année complète utilisée pour calculer le coût annuel.
        annee_cout_annuel = obtenir_annee_pour_cout_annuel(date_meteo)

        temperatures_annuelles = meteo_service.temperatures_moyennes_journalieres_annee(
            annee_cout_annuel
        )

        # Simulation avec l'isolation choisie par l'utilisateur.
        batiment, resultats_thermiques, resultats_cout = calculer_simulation_complete(
            composantes=composantes_recues,
            temperature_interieure=temperature_interieure,
            temperature_exterieure=temperature_exterieure,
            type_chauffage=type_chauffage,
            heures_chauffage_par_an=heures_chauffage_par_an,
            nb_occupants=nb_occupants,
            temperatures_annuelles=temperatures_annuelles
        )

        # Simulation de référence avec isolation moyenne.
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

        # On ajoute les économies dans les résultats envoyés à Godot.
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
                "annee_cout_annuel": annee_cout_annuel
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

    except Exception as erreur:
        return jsonify({
            "message": "Erreur pendant la simulation.",
            "erreur": str(erreur)
        }), 500