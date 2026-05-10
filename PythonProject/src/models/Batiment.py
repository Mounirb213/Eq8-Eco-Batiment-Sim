from models.ComposantBatiment import ComposantBatiment


class Batiment:
    """
    Représente le bâtiment complet.

    Un bâtiment contient plusieurs composantes :
    - murs
    - fenêtres
    - portes
    - toit
    - sols
    - plafonds

    Cette classe sert surtout à organiser les composantes reçues de Godot.
    """

    def __init__(self, composantes=None):
        """
        Crée un bâtiment.

        Si une liste de composantes est donnée, on les ajoute une par une.
        Les composantes peuvent être :
        - des objets ComposantBatiment
        - des dictionnaires venant du JSON de Godot
        """
        self.composantes = []

        if composantes is not None:
            for composante in composantes:
                self.ajouter_composante(composante)

    def ajouter_composante(self, composante):
        """
        Ajoute une composante dans le bâtiment.

        Si c'est déjà un objet ComposantBatiment, on l'ajoute directement.
        Si c'est un dictionnaire, on le convertit en objet ComposantBatiment.
        """

        if isinstance(composante, ComposantBatiment):
            self.composantes.append(composante)

        elif isinstance(composante, dict):
            nouvelle_composante = ComposantBatiment.from_dict(composante)
            self.composantes.append(nouvelle_composante)

    # --------------------------------------------------
    # Récupération des composantes
    # --------------------------------------------------

    def toutes_les_composantes(self):
        """
        Retourne toutes les composantes du bâtiment.
        """
        return self.composantes

    def composantes_energetiques(self):
        """
        Retourne seulement les composantes utilisées pour le calcul thermique.

        - les murs extérieurs comptent
        - les faces intérieures ne comptent pas, sauf si prise_en_compte vaut True
        """
        composantes_a_calculer = []

        for composante in self.composantes:
            if composante.doit_compter_pour_energie():
                composantes_a_calculer.append(composante)

        return composantes_a_calculer

    def composantes_thermographie(self):
        """
        Retourne les composantes utilisées pour l'affichage thermographique.

        Pour l'affichage, on garde toutes les composantes.
        Même une composante qui ne compte pas dans le calcul peut recevoir une couleur.
        """
        return self.composantes

    def composantes_par_type(self, type_composant):
        """
        Retourne les composantes qui ont un certain type.

        Exemple :
        composantes_par_type("mur") retourne seulement les murs.
        """
        composantes_trouvees = []

        for composante in self.composantes:
            if composante.type_composant == type_composant:
                composantes_trouvees.append(composante)

        return composantes_trouvees

    # --------------------------------------------------
    # Calculs simples sur les surfaces
    # --------------------------------------------------

    def surface_totale(self):
        """
        Calcule la surface totale de toutes les composantes.
        """
        total = 0.0

        for composante in self.composantes:
            total += composante.surface

        return total

    def surface_totale_energetique(self):
        """
        Calcule la surface totale utilisée pour le calcul énergétique.

        Cette surface est différente de la surface totale,
        parce que certaines composantes ne comptent pas dans le calcul.
        """
        total = 0.0

        for composante in self.composantes_energetiques():
            total += composante.surface

        return total

    def nombre_de_composantes(self):
        """
        Retourne le nombre total de composantes dans le bâtiment.
        """
        return len(self.composantes)

    # --------------------------------------------------
    # Conversion en dictionnaire
    # --------------------------------------------------

    def to_dict(self):
        """
        Convertit le bâtiment en dictionnaire.

        Ça permet de retourner les informations du bâtiment en JSON.
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