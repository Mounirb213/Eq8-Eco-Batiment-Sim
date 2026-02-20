from flask import Blueprint, jsonify, request

api_routes = Blueprint("api_routes", __name__)

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
    temp_int = float(data.get("temp_interieur_c", 21.0))

    #Reponse test
    response = {
        "received": {
            "surface_m2": surface_m2,
            "nb_occupants": nb_occupants,
            "chauffage": chauffage,
            "isolation": isolation,
            "date": date,
            "temp_interieur_c": temp_int,
        },
        "message": "OK - endpoint /simulate fonctionne."
    }

    return jsonify(response), 200
