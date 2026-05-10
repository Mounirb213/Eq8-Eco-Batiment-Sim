from models.Batiment import Batiment


class CalculThermique:
    """
    Calcule les pertes thermiques du bâtiment.

    Formule principale :
        Q = U × A × ΔT

    Où :
    - Q = perte thermique en watts
    - U = coefficient d'isolation
    - A = surface
    - ΔT = différence entre température intérieure et extérieure
    """

    def __init__(self, batiment, temperature_interieure, temperature_exterieure):
        self.batiment = self.valider_batiment(batiment)
        self.temperature_interieure = self.valider_temperature(temperature_interieure)
        self.temperature_exterieure = self.valider_temperature(temperature_exterieure)

        # Coefficients U approximatifs selon le type de composante et l'isolation.
        # Plus le coefficient est élevé, plus la composante perd de chaleur.
        self.coefficients_u = {
            "mur": {
                "mauvaise": 1.2,
                "moyenne": 0.8,
                "bonne": 0.5,
                "tres_bonne": 0.3
            },
            "fenetre": {
                "mauvaise": 3.0,
                "moyenne": 2.2,
                "bonne": 1.6,
                "tres_bonne": 1.2
            },
            "toit": {
                "mauvaise": 0.9,
                "moyenne": 0.6,
                "bonne": 0.35,
                "tres_bonne": 0.2
            },
            "porte": {
                "mauvaise": 2.5,
                "moyenne": 1.8,
                "bonne": 1.2,
                "tres_bonne": 0.8
            },
            "sol": {
                "mauvaise": 1.0,
                "moyenne": 0.7,
                "bonne": 0.4,
                "tres_bonne": 0.25
            },
            "plafond": {
                "mauvaise": 0.8,
                "moyenne": 0.5,
                "bonne": 0.3,
                "tres_bonne": 0.2
            }
        }

    # --------------------------------------------------
    # Calculs de base
    # --------------------------------------------------

    def calculer_delta_t(self):
        """
        Calcule la différence de température.

        Si la température extérieure est plus chaude que l'intérieur,
        on retourne 0 parce qu'il n'y a pas de perte de chauffage.
        """
        delta_t = self.temperature_interieure - self.temperature_exterieure

        if delta_t < 0:
            return 0.0

        return delta_t

    def obtenir_coefficient_u(self, type_composant, isolation_type):
        """
        Retourne le coefficient U selon le type de composante.

        Exemple :
        - mur avec isolation moyenne
        - fenêtre avec bonne isolation
        """
        if type_composant in self.coefficients_u:
            coefficients_par_isolation = self.coefficients_u[type_composant]

            if isolation_type in coefficients_par_isolation:
                return coefficients_par_isolation[isolation_type]

        # Si le type ou l'isolation n'existe pas, on ne compte pas de perte.
        return 0.0

    def calculer_perte_composante(self, composante):
        """
        Calcule la perte thermique d'une seule composante.
        """
        coefficient_u = self.obtenir_coefficient_u(
            composante.type_composant,
            composante.isolation_type
        )

        delta_t = self.calculer_delta_t()

        perte = coefficient_u * composante.surface * delta_t

        return perte

    # --------------------------------------------------
    # Thermographie
    # --------------------------------------------------

    def generer_thermographie(self):
        """
        Prépare les températures à envoyer à Godot pour colorer la maison.

        Exemple :
        {
            "Mur_Ch01": {
                "int": 21.0,
                "ext": -5.0
            }
        }
        """
        thermographie = {}

        for composante in self.batiment.composantes_thermographie():
            nom_logique = composante.nom_logique

            # Si c'est la première fois qu'on voit ce nom logique,
            # on crée une entrée pour lui.
            if nom_logique not in thermographie:
                thermographie[nom_logique] = {
                    "int": None,
                    "ext": None
                }

            # On met la température intérieure ou extérieure selon la face.
            if composante.est_interieur():
                thermographie[nom_logique]["int"] = self.temperature_interieure

            if composante.est_exterieur():
                thermographie[nom_logique]["ext"] = self.temperature_exterieure

        return thermographie

    # --------------------------------------------------
    # Calcul principal
    # --------------------------------------------------

    def calculer(self):
        """
        Calcule les pertes thermiques du bâtiment.

        Cette méthode retourne les résultats que Flask va envoyer à Godot.
        """
        resultat = {
            "murs": 0.0,
            "fenetres": 0.0,
            "toit": 0.0,
            "portes": 0.0,
            "sols": 0.0,
            "plafonds": 0.0,
            "total": 0.0,
            "pertes_par_composant": {},
            "thermographie": {}
        }

        for composante in self.batiment.composantes_energetiques():
            perte = self.calculer_perte_composante(composante)

            # On garde la perte de chaque composante pour la thermographie dans Godot.
            resultat["pertes_par_composant"][composante.nom] = round(perte, 2)

            # On ajoute au total général.
            resultat["total"] += perte

            # On ajoute aussi dans la bonne catégorie.
            if composante.type_composant == "mur":
                resultat["murs"] += perte

            elif composante.type_composant == "fenetre":
                resultat["fenetres"] += perte

            elif composante.type_composant == "toit":
                resultat["toit"] += perte

            elif composante.type_composant == "porte":
                resultat["portes"] += perte

            elif composante.type_composant == "sol":
                resultat["sols"] += perte

            elif composante.type_composant == "plafond":
                resultat["plafonds"] += perte

        # On arrondit les résultats pour éviter d'envoyer trop de décimales à Godot.
        resultat["murs"] = round(resultat["murs"], 2)
        resultat["fenetres"] = round(resultat["fenetres"], 2)
        resultat["toit"] = round(resultat["toit"], 2)
        resultat["portes"] = round(resultat["portes"], 2)
        resultat["sols"] = round(resultat["sols"], 2)
        resultat["plafonds"] = round(resultat["plafonds"], 2)
        resultat["total"] = round(resultat["total"], 2)

        # La thermographie sert seulement à l'affichage visuel dans Godot.
        resultat["thermographie"] = self.generer_thermographie()

        return resultat

    # --------------------------------------------------
    # Calcul annuel du chauffage
    # --------------------------------------------------

    def calculer_coefficient_global_ua(self):
        """
        Calcule la somme U × A de toutes les composantes énergétiques.

        Cette valeur représente la perte globale du bâtiment.
        Unité : W/K

        Aidé avec ChatGPT
        """
        total_ua = 0.0

        for composante in self.batiment.composantes_energetiques():
            coefficient_u = self.obtenir_coefficient_u(
                composante.type_composant,
                composante.isolation_type
            )

            total_ua += coefficient_u * composante.surface

        return total_ua

    def calculer_besoin_thermique_annuel_kwh(self, temperatures_exterieures_journalieres):
        """
        Calcule le besoin de chauffage sur une année complète.

        Au lieu de prendre une seule journée et de la multiplier par l'année,
        on utilise les températures de chaque jour.

        Si une journée est plus chaude que l'intérieur, on ne compte pas de chauffage.

        Aidé avec ChatGPT
        """
        coefficient_global_ua = self.calculer_coefficient_global_ua()

        besoin_annuel_kwh = 0.0

        for temperature_exterieure_jour in temperatures_exterieures_journalieres:
            delta_t = self.temperature_interieure - float(temperature_exterieure_jour)

            if delta_t < 0:
                delta_t = 0.0

            # Énergie d'une journée :
            # W/K × °C × 24 h = Wh
            # On divise par 1000 pour obtenir des kWh.
            energie_jour_kwh = (coefficient_global_ua * delta_t * 24) / 1000

            besoin_annuel_kwh += energie_jour_kwh

        return round(besoin_annuel_kwh, 2)

    # --------------------------------------------------
    # Validations
    # --------------------------------------------------

    def valider_batiment(self, batiment):
        """
        Vérifie que l'objet reçu est bien un bâtiment.
        """
        if isinstance(batiment, Batiment):
            return batiment

        return Batiment()

    def valider_temperature(self, temperature):
        """
        Vérifie que la température est un nombre.
        """
        try:
            return float(temperature)
        except (TypeError, ValueError):
            return 0.0