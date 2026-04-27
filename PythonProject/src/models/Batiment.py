from models.ComposantBatiment import ComposantBatiment


class Batiment:
    """
    Représente un bâtiment contenant plusieurs composantes.

    Cette classe sert à :
    - stocker toutes les composantes du bâtiment
    - retourner les composantes utiles pour l'énergie
    - retourner les composantes utiles pour la thermographie
    - calculer des surfaces totales
    """

    def __init__(self, composantes=None):
        """
        Initialise le bâtiment avec une liste de composantes.

        Paramètre :
        - composantes : liste d'objets ComposantBatiment ou liste de dictionnaires venant de Godot
        """
        self.composantes = []

        if composantes is not None:
            for composante in composantes:
                self.ajouter_composante(composante)

    def ajouter_composante(self, composante):
        """
        Ajoute une composante au bâtiment.

        On accepte :
        - un objet ComposantBatiment
        - un dictionnaire, qui sera converti avec from_dict()
        """
        if isinstance(composante, ComposantBatiment):
            self.composantes.append(composante)

        elif isinstance(composante, dict):
            nouvelle_composante = ComposantBatiment.from_dict(composante)
            self.composantes.append(nouvelle_composante)

    def toutes_les_composantes(self):
        """
        Retourne toutes les composantes du bâtiment.
        """
        return self.composantes

    def composantes_energetiques(self):
        """
        Retourne seulement les composantes qui doivent être utilisées pour le calcul énergétique.
        """
        composantes_a_calculer = []

        for composante in self.composantes:
            if composante.doit_compter_pour_energie():
                composantes_a_calculer.append(composante)

        return composantes_a_calculer

    def composantes_thermographie(self):
        """
        Retourne toutes les composantes à afficher dans la thermographie.
        """
        return self.composantes

    def composantes_par_type(self, type_composant):
        """
        Retourne toutes les composantes d'un certain type. Exemple : mur, fenetre, toit, porte
        """
        resultat = []

        for composante in self.composantes:
            if composante.type_composant == type_composant:
                resultat.append(composante)

        return resultat

    def surface_totale(self):
        """
        Retourne la surface totale de toutes les composantes.
        """
        total = 0.0

        for composante in self.composantes:
            total += composante.surface

        return total

    def surface_totale_energetique(self):
        """
        Retourne la surface totale des composantes utilisées pour le calcul énergétique.
        """
        total = 0.0

        for composante in self.composantes_energetiques():
            total += composante.surface

        return total

    def nombre_de_composantes(self):
        """
        Retourne le nombre total de composantes.
        """
        return len(self.composantes)

    def to_dict(self):
        """
        Convertit le bâtiment en dictionnaire JSON.
        """
        liste_composantes = []

        for composante in self.composantes:
            liste_composantes.append(composante.to_dict())

        return {
            "nombre_de_composantes": self.nombre_de_composantes(),
            "surface_totale": self.surface_totale(),
            "surface_totale_energetique": self.surface_totale_energetique(),
            "composantes": liste_composantes
        }

    def __repr__(self):
        return (
            f"Batiment("
            f"nombre_de_composantes={self.nombre_de_composantes()}, "
            f"surface_totale={self.surface_totale()}, "
            f"surface_totale_energetique={self.surface_totale_energetique()})"
        )