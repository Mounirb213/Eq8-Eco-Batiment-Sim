from flask import Flask
from api.routes import api_routes


# Création de l'application Flask.
app = Flask(__name__)

# On ajoute les routes de l'API.
# Les routes sont dans le fichier api/routes.py.
app.register_blueprint(api_routes)


# Ce bloc sert à lancer le serveur Flask.
# Godot va ensuite envoyer ses données à http://127.0.0.1:5000/simulate
if __name__ == "__main__":
    app.run(
        host="127.0.0.1",      # Serveur local seulement
        port=5000,             # Port utilisé par Godot
        debug=False,           # On désactive le debug pour éviter les doubles lancements
        use_reloader=False     # Évite que Flask redémarre automatiquement deux fois
    )