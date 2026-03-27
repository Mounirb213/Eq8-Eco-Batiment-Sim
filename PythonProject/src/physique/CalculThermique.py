class CalculThermique:
    """
    Formule utilisée:
        Q = U * A * ΔT
    Où :
        Q = perte thermique (W)
        U = coefficient de transmission thermique (W/m²K)
        A = surface (m²)
        ΔT = différence de température (°C)
    """

    def __init__(self):
        """
        Coefficient U simplifiés selon le type de composante et sa qualité d'isolation.
        Plus U est grand -> plus grande perte de chaleur
        """

        self.coefficient_u = {
            "mur": {
                "mauvaise": 1.2,
                "moyenne": 0.7,
                "bonne": 0.4,
                "tres_bonne": 0.25
            },
            "fenetre": {
                "mauvaise": 5.0,
                "moyenne": 2.7,
                "bonne": 1.4,
                "tres_bonne": 0.9
            },
            "toit": {
                "mauvaise": 0.8,
                "moyenne": 0.5,
                "bonne": 0.25,
                "tres_bonne": 0.15
            },
            "porte": {
                "mauvaise": 3.0,
                "moyenne": 2.0,
                "bonne": 1.5,
                "tres_bonne": 1.0
            }
        }

    def obtenir_u(self, type_composant, isolation):
        """
        Retourne le coefficient U correspondant au type de composante et au niveau de d'isolation
        Si valeur n'existe pas, on utilise moyenne par defaut
        """
        type_composant = type_composant.lower()
        isolation = isolation.lower()

        if type_composant not in self.coefficient_u:
            return 1.0

        return self.coefficients_u