class ComposantBatiment:
    """
    Représente une composante de la maison.

    Exemple :
    - Mur_Ch01_Ext_01
    - Mur_Ch01_Int_01
    - Fenetre_Ch01_01

    Cette classe sert à garder les informations envoyées par Godot.
    """

    def __init__(
        self,
        nom,
        nom_logique,
        surface,
        type_composant,
        face,
        isolation_type="moyenne",
        prise_en_compte=False
    ):
        # On valide les valeurs au moment de créer l'objet.
        self.nom = self.valider_nom(nom)
        self.nom_logique = self.valider_nom_logique(nom_logique)
        self.surface = self.valider_surface(surface)
        self.type_composant = self.valider_type_composant(type_composant)
        self.face = self.valider_face(face)
        self.isolation_type = self.valider_isolation_type(isolation_type)
        self.prise_en_compte = self.convertir_en_bool(prise_en_compte)

    @classmethod
    def from_dict(cls, data):
        """
        Crée un objet ComposantBatiment à partir d'un dictionnaire.

        Godot envoie les composantes sous forme de dictionnaires JSON.
        Cette méthode transforme ce dictionnaire en objet Python.
        """
        return cls(
            nom=data.get("nom", ""),
            nom_logique=data.get("nom_logique", ""),
            surface=data.get("surface", 0),
            type_composant=data.get("type_composant", ""),
            face=data.get("face", ""),
            isolation_type=data.get("isolation_type", "moyenne"),
            prise_en_compte=data.get("prise_en_compte", False)
        )

    # --------------------------------------------------
    # Méthodes utiles
    # --------------------------------------------------

    def est_exterieur(self):
        """
        Retourne True si la composante est une face extérieure.
        """
        return self.face == "ext"

    def est_interieur(self):
        """
        Retourne True si la composante est une face intérieure.
        """
        return self.face == "int"

    def doit_compter_pour_energie(self):
        """
        Décide si cette composante doit être utilisée dans le calcul énergétique.

        Dans notre projet :
        - les faces extérieures comptent toujours
        - les faces intérieures comptent seulement si prise_en_compte vaut True
        """
        if self.est_exterieur():
            return True

        if self.prise_en_compte:
            return True

        return False

    def to_dict(self):
        """
        Convertit l'objet en dictionnaire.

        Ça permet de retourner facilement les données en JSON.
        """
        return {
            "nom": self.nom,
            "nom_logique": self.nom_logique,
            "surface": self.surface,
            "type_composant": self.type_composant,
            "face": self.face,
            "isolation_type": self.isolation_type,
            "prise_en_compte": self.prise_en_compte
        }

    # --------------------------------------------------
    # Méthodes de validation
    # --------------------------------------------------

    def valider_nom(self, nom):
        """
        Vérifie le nom de la composante.

        Si le nom est vide, on donne un nom par défaut pour éviter une erreur.
        """
        nom = str(nom).strip()

        if nom == "":
            return "Composant_sans_nom"

        return nom

    def valider_nom_logique(self, nom_logique):
        """
        Vérifie le nom logique.

        Le nom logique sert à regrouper les faces intérieures/extérieures.
        Exemple :
        Mur_Ch01_Ext_01 et Mur_Ch01_Int_01 ont le même nom logique : Mur_Ch01.
        """
        nom_logique = str(nom_logique).strip()

        if nom_logique == "":
            return "Composant_sans_nom_logique"

        return nom_logique

    def valider_surface(self, surface):
        """
        Vérifie que la surface est un nombre positif.
        """
        try:
            surface = float(surface)
        except (TypeError, ValueError):
            return 0.0

        if surface < 0:
            return 0.0

        return surface

    def valider_type_composant(self, type_composant):
        """
        Vérifie le type de composante.

        Godot doit normalement envoyer une de ces valeurs :
        mur, fenetre, toit, porte, sol, plafond.
        """
        type_composant = str(type_composant).strip().lower()

        types_valides = [
            "mur",
            "fenetre",
            "toit",
            "porte",
            "sol",
            "plafond"
        ]

        if type_composant in types_valides:
            return type_composant

        # Valeur par défaut si Godot envoie quelque chose de vide ou invalide.
        return "mur"

    def valider_face(self, face):
        """
        Vérifie si la face est intérieure ou extérieure.

        Dans Godot, on envoie seulement :
        - int
        - ext
        """
        face = str(face).strip().lower()

        if face == "int":
            return "int"

        if face == "ext":
            return "ext"

        # Par défaut, on considère que c'est une face extérieure.
        return "ext"

    def valider_isolation_type(self, isolation_type):
        """
        Vérifie le type d'isolation.
        """
        isolation_type = str(isolation_type).strip().lower()

        valeurs_valides = [
            "mauvaise",
            "moyenne",
            "bonne",
            "tres_bonne"
        ]

        if isolation_type in valeurs_valides:
            return isolation_type

        return "moyenne"

    def convertir_en_bool(self, valeur):
        """
        Convertit une valeur en booléen.

        Godot envoie normalement true ou false.
        Cette fonction garde quand même une petite sécurité.
        """
        if isinstance(valeur, bool):
            return valeur

        if isinstance(valeur, str):
            valeur = valeur.strip().lower()

            if valeur == "true":
                return True

            if valeur == "false":
                return False

        if isinstance(valeur, (int, float)):
            return bool(valeur)

        return False