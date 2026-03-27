from models.ComposantBatiment import ComposantBatiment

class Batiment:
    """
    Represente les differentes composantes envoyées de Godot

    Chaque élément est representé par un dictionnaire (ressemble a liste) contenant: surface: surface en metres carres
    """

    def __init__(self, nb_occupants, temp_interieure, chauffage_type, murs=None, fenetres=None, toit=None, portes=None):

        #Nombre de personnes dans la maison
        #influence les pertes et gains thermiques et la consommation énergétique totale
        self.nb_occupants = nb_occupants

        #température interieure souhaitée
        self.temp_interieure = temp_interieure

        #type de chauffage utilisé
        self.chauffage_type = chauffage_type

        #si Godot envoi une liste, on l'utilise. sinon on crée une nouvelle liste vide
        #sinon ca creerait une liste partagée entre plusieurs objets

        if murs is not None:
            # Godot envoi les objets
            self.murs = murs
        else :
            # si rien n'est fourni
            self.murs = []

        if fenetres is not None:
            self.fenetres = fenetres
        else :
            self.fenetres = []

        if toit is not None:
            self.toit = toit
        else :
            self.toit = []

        if portes is not None:
            self.portes = portes
        else :
            self.portes = []


    #Calculer la surface totale du batiment en additionnant les surfaces de toutes les composantes
    def surface_totale(self):

        # Surface des murs
        surface_murs = 0
        # mur est dictionnarie et on récupere la surface de chaque mur
        for element_murs in self.murs:
            surface_murs += element_murs.get("surface", 0)

        # Surface des fenetres
        surface_fenetres = 0
        for fenetre in self.fenetres:
            surface_fenetres += fenetre.get("surface", 0)

        #Surface du toit
        surface_toit = 0
        for element_toit in self.toit:
            surface_toit += element_toit.get("surface", 0)

        #Surface des portes
        surface_portes = 0
        for porte in self.portes:
            surface_portes += porte.get("surface", 0)


        #Surface totale
        surface_totale = (surface_murs + surface_fenetres + surface_toit + surface_portes)

        return surface_totale