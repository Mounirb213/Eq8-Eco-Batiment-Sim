from models.Batiment import Batiment


class CalculThermique:
    """
    Calculer les pertes thermiques d'un bâtiment.

    Formule utilisée :
    Q = U * A * ΔT

    Où :
    - Q = perte thermique
    - U = coefficient de transmission thermique
    - A = surface
    - ΔT = température intérieure - température extérieure
    """

    def __init__(self, batiment, temperature_interieure, temperature_exterieure):
        self.batiment = self.valider_batiment(batiment)
        self.temperature_interieure = self.valider_temperature(temperature_interieure)
        self.temperature_exterieure = self.valider_temperature(temperature_exterieure)

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

    def calculer_delta_t(self):
        """
        Retourne la différence de température.

        Si la température extérieure est plus grande que la température intérieure,
        on retourne 0 pour éviter une perte négative.
        """
        delta_t = self.temperature_interieure - self.temperature_exterieure

        if delta_t < 0:
            return 0.0

        return delta_t

    def obtenir_coefficient_u(self, type_composant, isolation_type):
        """
        Retourne le coefficient U selon le type de composant et l'isolation.
        """
        if type_composant in self.coefficients_u:
            if isolation_type in self.coefficients_u[type_composant]:
                return self.coefficients_u[type_composant][isolation_type]

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

    def generer_thermographie(self):
        """
        Structure pour la thermographie.

        Exemple de retour :
            "Mur_Ch01": {
                "int": 21.0,
                "ext": -5.0
            }
        """
        thermographie = {}

        for composante in self.batiment.composantes_thermographie():
            nom_logique = composante.nom_logique

            if nom_logique not in thermographie:
                thermographie[nom_logique] = {
                    "int": None,
                    "ext": None
                }

            if composante.est_interieur():
                thermographie[nom_logique]["int"] = self.temperature_interieure

            if composante.est_exterieur():
                thermographie[nom_logique]["ext"] = self.temperature_exterieure

        return thermographie

    def calculer(self):
        """
        Calcule toutes les pertes thermiques du bâtiment et retourne un dictionnaire.
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

            resultat["pertes_par_composant"][composante.nom] = round(perte, 2)
            resultat["total"] += perte

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

        resultat["murs"] = round(resultat["murs"], 2)
        resultat["fenetres"] = round(resultat["fenetres"], 2)
        resultat["toit"] = round(resultat["toit"], 2)
        resultat["portes"] = round(resultat["portes"], 2)
        resultat["sols"] = round(resultat["sols"], 2)
        resultat["plafonds"] = round(resultat["plafonds"], 2)
        resultat["total"] = round(resultat["total"], 2)

        resultat["thermographie"] = self.generer_thermographie()

        return resultat

    # Methodes de validation

    def valider_batiment(self, batiment):
        if isinstance(batiment, Batiment):
            return batiment

        return Batiment()

    def valider_temperature(self, temperature):
        try:
            temperature = float(temperature)
        except (TypeError, ValueError):
            return 0.0

        return temperature