class ComposantBatiment:
    """
    Represente une composante du batiment:
    -> mur, fenetre, toit, porte, sol, plafond.
    """

    def __init__(self, nom, type_composant, surface_m2, isolation_type = "moyenne"):
        self.nom = nom
        self.type_composant = type_composant.lower()
        self.surface_m2 = float(surface_m2)
        self.isolation_type = isolation_type.lower()

    def to_dict(self):
        return {
            "nom": self.nom,
            "type_composant": self.type_composant,
            "surface_m2": self.surface_m2,
            "isolation_type": self.isolation_type
        }