class ComposantBatiment:
    """
    Représente une composante individuelle du batiment

    Exemple :
    - Mur_Ch01_Ext_01
    - Mur_Ch01_Int_01
    - Fenetre_Salon_Ext_01

    Cette classe sert à :
    - stocker les infos d'une composante
    - savoir si elle est int/ext
    - savoir si elle doit être utilisée pour le calcul énergétique
    - convertir l'objet en dictionnaire pour le JSON
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
        self.nom = self.valider_nom(nom)
        self.nom_logique = self.valider_nom_logique(nom_logique)
        self.surface = self.valider_surface(surface)
        self.type_composant = self.valider_type_composant(type_composant)
        self.face = self.valider_face(face)
        self.isolation_type = self.valider_isolation_type(isolation_type)
        self.prise_en_compte = self.convertir_en_bool(prise_en_compte)

    @classmethod #Définit une methode liée à la classe elle-même et pas à l'objet
    def from_dict(cls,data):
        '''
        Crée un objet ComposantBatiment à partir d'un dictionnaire reçu de Godot.
        :param data:
        :return:
        '''
        return cls(
            nom=data.get("nom", ""),
            nom_logique=data.get("nom_logique", ""),
            surface=data.get("surface", 0),
            type_composant=data.get("type_composant", ""),
            face=data.get("face", ""),
            isolation_type=data.get("isolation_type", "moyenne"),
            prise_en_compte=data.get("prise_en_compte", False)
        )

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
        - toute composante extérieure compte
        - une composante intérieure peut compter si prise_en_compte = True
        """
        if self.est_exterieur():
            return True

        if self.prise_en_compte:
            return True

        return False

    def to_dict(self):
        """
        Convertit l'objet en dictionnaire JSON.
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

    def __repr__(self):
        return (
            f"ComposantBatiment("                         # f permet d'inserer des variable dans du texte
            f"nom='{self.nom}', "
            f"nom_logique='{self.nom_logique}', "
            f"surface={self.surface}, "
            f"type_composant='{self.type_composant}', "
            f"face='{self.face}', "
            f"isolation_type='{self.isolation_type}', "
            f"prise_en_compte={self.prise_en_compte})"
        )

    # Methodes de validation

    def valider_nom(self, nom):
        nom = str(nom).strip()

        if nom == "":
            return "Composant_sans_nom"

        return nom

    def valider_nom_logique(self, nom_logique):
        nom_logique = str(nom_logique).strip()

        if nom_logique == "":
            return "Composant_sans_nom_logique"

        return nom_logique

    def valider_surface(self, surface):
        try:
            surface = float(surface)
        except (TypeError, ValueError):
            return 0.0

        if surface < 0:
            return 0.0

        return surface

    def valider_type_composant(self, type_composant):
        type_composant = str(type_composant).strip().lower()

        types_valides = [
            "mur",
            "fenetre",
            "toit",
            "porte",
            "sol",
            "plafond"
        ]

        if type_composant not in types_valides:
            return "mur"

        return type_composant

    def valider_face(self, face):
        face = str(face).strip().lower()

        if face == "interieur":
            face = "int"
        elif face == "exterieur":
            face = "ext"

        faces_valides = ["int", "ext"]

        if face not in faces_valides:
            return "ext"

        return face

    def valider_isolation_type(self, isolation_type):
        isolation_type = str(isolation_type).strip().lower()

        if isolation_type == "très bonne":
            isolation_type = "tres_bonne"

        valeurs_valides = [
            "mauvaise",
            "moyenne",
            "bonne",
            "tres_bonne"
        ]

        if isolation_type not in valeurs_valides:
            return "moyenne"

        return isolation_type

    def convertir_en_bool(self, valeur):
        if isinstance(valeur, bool):
            return valeur

        if isinstance(valeur, str):
            valeur = valeur.strip().lower()

            if valeur in ["true"]:
                return True

            if valeur in ["false"]:
                return False

        if isinstance(valeur, (int, float)):
            return bool(valeur)

        return False