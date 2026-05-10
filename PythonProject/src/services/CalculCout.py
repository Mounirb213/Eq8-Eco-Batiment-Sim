class CalculCout:
    """
    Calcule la consommation annuelle et le coût annuel du bâtiment.

    Le calcul prend en compte le chauffage et le nombre d'occupants

    Le chauffage dépend des pertes thermiques du bâtiment.
    Les occupants ajoutent une consommation normale d'électricité
    pour les appareils, l'eau chaude, l'éclairage, etc.
    """

    def __init__(
        self,
        perte_totale_watts,
        type_chauffage="chauffage_electrique",
        heures_chauffage_par_an=4320,
        nb_occupants=1,
        besoin_thermique_annuel_kwh=None
    ):
        # Valeurs principales reçues de routes.py
        self.perte_totale_watts = self.valider_perte_totale_watts(perte_totale_watts)
        self.type_chauffage = self.valider_type_chauffage(type_chauffage)
        self.heures_chauffage_par_an = self.valider_heures_chauffage_par_an(heures_chauffage_par_an)
        self.nb_occupants = self.valider_nb_occupants(nb_occupants)

        # Si routes.py calcule déjà le besoin annuel avec les températures de l'année,
        # on utilise cette valeur.
        self.besoin_thermique_annuel_kwh = self.valider_besoin_thermique_annuel_kwh(
            besoin_thermique_annuel_kwh
        )

        # Tarif approximatif selon le type de chauffage.
        self.tarifs_kwh = {
            "chauffage_electrique": 0.10,
            "chauffage_gaz": 0.07,
            "thermopompe": 0.10,
            "chauffage_mazout": 0.12
        }

        # Rendement approximatif selon le système de chauffage.
        # Une thermopompe a un rendement plus élevé, donc elle consomme moins.
        self.rendements = {
            "chauffage_electrique": 1.0,
            "chauffage_gaz": 0.9,
            "thermopompe": 2.8,
            "chauffage_mazout": 0.85
        }

        # Consommation annuelle estimée selon le nombre d'occupants.
        # Aidé avec ChatGPT
        self.consommation_occupants_kwh_an = {
            1: 1000,
            2: 1800,
            3: 2500,
            4: 3200,
            5: 3900
        }

        # Tarif utilisé pour la consommation normale des occupants.
        self.tarif_occupants_kwh = 0.10

    # --------------------------------------------------
    # Données de base
    # --------------------------------------------------

    def obtenir_tarif_kwh(self):
        """
        Retourne le tarif du chauffage selon le type choisi.
        """
        return self.tarifs_kwh[self.type_chauffage]

    def obtenir_rendement(self):
        """
        Retourne le rendement du système de chauffage.
        """
        return self.rendements[self.type_chauffage]

    # --------------------------------------------------
    # Chauffage
    # --------------------------------------------------

    def calculer_besoin_thermique_annuel_kwh(self):
        """
        Calcule le besoin thermique annuel.

        Si on a déjà un calcul annuel basé sur les températures de l'année,
        on l'utilise directement.

        Sinon, on utilise l'ancien calcul simple :
        perte en watts × heures de chauffage / 1000.
        """
        if self.besoin_thermique_annuel_kwh is not None:
            return self.besoin_thermique_annuel_kwh

        besoin_thermique = (self.perte_totale_watts * self.heures_chauffage_par_an) / 1000

        return besoin_thermique

    def calculer_consommation_chauffage_kwh_an(self):
        """
        Calcule la consommation annuelle du chauffage.

        Exemple :
        si le besoin est de 3000 kWh et que le rendement est 1,
        la consommation est 3000 kWh.
        """
        besoin_thermique = self.calculer_besoin_thermique_annuel_kwh()
        rendement = self.obtenir_rendement()

        consommation_chauffage = besoin_thermique / rendement

        return consommation_chauffage

    def calculer_cout_chauffage_annuel(self):
        """
        Calcule le coût annuel du chauffage.
        """
        consommation_chauffage = self.calculer_consommation_chauffage_kwh_an()
        tarif_chauffage = self.obtenir_tarif_kwh()

        cout_chauffage = consommation_chauffage * tarif_chauffage

        return cout_chauffage

    # --------------------------------------------------
    # Occupants
    # --------------------------------------------------

    def calculer_consommation_occupants_kwh_an(self):
        """
        Calcule la consommation annuelle liée aux occupants.

        Godot envoie seulement un nombre entre 1 et 5.
        """
        return self.consommation_occupants_kwh_an[self.nb_occupants]

    def calculer_cout_occupants_annuel(self):
        """
        Calcule le coût annuel lié aux occupants.
        """
        consommation_occupants = self.calculer_consommation_occupants_kwh_an()

        cout_occupants = consommation_occupants * self.tarif_occupants_kwh

        return cout_occupants

    # --------------------------------------------------
    # Totaux
    # --------------------------------------------------

    def calculer_consommation_totale_kwh_an(self):
        """
        Calcule la consommation annuelle totale.

        Total =
        consommation du chauffage + consommation des occupants.
        """
        consommation_chauffage = self.calculer_consommation_chauffage_kwh_an()
        consommation_occupants = self.calculer_consommation_occupants_kwh_an()

        consommation_totale = consommation_chauffage + consommation_occupants

        return consommation_totale

    def calculer_cout_annuel(self):
        """
        Calcule le coût annuel total.

        Total =
        coût du chauffage + coût des occupants.
        """
        cout_chauffage = self.calculer_cout_chauffage_annuel()
        cout_occupants = self.calculer_cout_occupants_annuel()

        cout_total = cout_chauffage + cout_occupants

        return cout_total

    # --------------------------------------------------
    # Résultat final
    # --------------------------------------------------

    def calculer_resultats(self):
        """
        Retourne tous les résultats dans un dictionnaire.

        Ce dictionnaire est envoyé à Godot par routes.py.
        """
        besoin_thermique = self.calculer_besoin_thermique_annuel_kwh()

        consommation_chauffage = self.calculer_consommation_chauffage_kwh_an()
        consommation_occupants = self.calculer_consommation_occupants_kwh_an()
        consommation_totale = self.calculer_consommation_totale_kwh_an()

        cout_chauffage = self.calculer_cout_chauffage_annuel()
        cout_occupants = self.calculer_cout_occupants_annuel()
        cout_total = self.calculer_cout_annuel()

        return {
            "type_chauffage": self.type_chauffage,
            "nb_occupants": self.nb_occupants,

            "heures_chauffage_par_an": self.heures_chauffage_par_an,

            "tarif_kwh": round(self.obtenir_tarif_kwh(), 4),
            "tarif_occupants_kwh": round(self.tarif_occupants_kwh, 4),
            "rendement": round(self.obtenir_rendement(), 2),

            "besoin_thermique_annuel_kwh": round(besoin_thermique, 2),

            "consommation_chauffage_kwh_an": round(consommation_chauffage, 2),
            "consommation_occupants_kwh_an": round(consommation_occupants, 2),
            "consommation_energetique_kwh_an": round(consommation_totale, 2),

            "cout_chauffage_annuel": round(cout_chauffage, 2),
            "cout_occupants_annuel": round(cout_occupants, 2),
            "cout_annuel": round(cout_total, 2)
        }

    # --------------------------------------------------
    # Validations
    # --------------------------------------------------

    def valider_perte_totale_watts(self, perte_totale_watts):
        """
        Vérifie que la perte thermique est un nombre positif.
        """
        try:
            perte_totale_watts = float(perte_totale_watts)
        except (TypeError, ValueError):
            return 0.0

        if perte_totale_watts < 0:
            return 0.0

        return perte_totale_watts

    def valider_heures_chauffage_par_an(self, heures_chauffage_par_an):
        """
        Vérifie le nombre d'heures de chauffage par année.
        """
        try:
            heures_chauffage_par_an = float(heures_chauffage_par_an)
        except (TypeError, ValueError):
            return 4320

        if heures_chauffage_par_an < 0:
            return 4320

        return heures_chauffage_par_an

    def valider_nb_occupants(self, nb_occupants):
        """
        Vérifie le nombre d'occupants.

        Dans Godot, les choix possibles sont de 1 à 5.
        """
        try:
            nb_occupants = int(nb_occupants)
        except (TypeError, ValueError):
            return 1

        if nb_occupants < 1:
            return 1

        if nb_occupants > 5:
            return 5

        return nb_occupants

    def valider_besoin_thermique_annuel_kwh(self, besoin_thermique_annuel_kwh):
        """
        Vérifie le besoin thermique annuel.

        Cette valeur peut être None, parce qu'elle n'est pas toujours fournie.
        """
        if besoin_thermique_annuel_kwh is None:
            return None

        try:
            besoin_thermique_annuel_kwh = float(besoin_thermique_annuel_kwh)
        except (TypeError, ValueError):
            return None

        if besoin_thermique_annuel_kwh < 0:
            return 0.0

        return besoin_thermique_annuel_kwh

    def valider_type_chauffage(self, type_chauffage):
        """
        Vérifie le type de chauffage.

        Godot envoie déjà une des valeurs suivantes :
        - chauffage_electrique
        - chauffage_gaz
        - thermopompe
        - chauffage_mazout
        """
        type_chauffage = str(type_chauffage).strip().lower()

        types_valides = [
            "chauffage_electrique",
            "chauffage_gaz",
            "thermopompe",
            "chauffage_mazout"
        ]

        if type_chauffage in types_valides:
            return type_chauffage

        return "chauffage_electrique"