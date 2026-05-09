class CalculCout:
    """
    Transforme les pertes thermiques en consommation énergétique annuelle et en coût annuel.

    Le coût total inclut maintenant :
    - la consommation de chauffage
    - la consommation liée au nombre d'occupants

    Formules :
        besoin_thermique_annuel_kwh = (perte_totale_watts * heures_chauffage_par_an) / 1000

        consommation_chauffage_kwh = besoin_thermique_annuel_kwh / rendement

        consommation_occupants_kwh = valeur selon le nombre d'occupants

        consommation_energetique_kwh_an = consommation_chauffage_kwh + consommation_occupants_kwh

        cout_annuel = cout_chauffage + cout_occupants
    """

    def __init__(
        self,
        perte_totale_watts,
        type_chauffage="chauffage_electrique",
        heures_chauffage_par_an=4320,
        nb_occupants=1
    ):
        self.perte_totale_watts = self.valider_perte_totale_watts(perte_totale_watts)
        self.type_chauffage = self.valider_type_chauffage(type_chauffage)
        self.heures_chauffage_par_an = self.valider_heures_chauffage_par_an(heures_chauffage_par_an)
        self.nb_occupants = self.valider_nb_occupants(nb_occupants)

        self.tarifs_kwh = {
            "chauffage_electrique": 0.10,
            "chauffage_gaz": 0.07,
            "thermopompe": 0.10,
            "chauffage_mazout": 0.12
        }

        self.rendements = {
            "chauffage_electrique": 1.0,
            "chauffage_gaz": 0.9,
            "thermopompe": 2.8,
            "chauffage_mazout": 0.85
        }

        # Consommation annuelle estimée selon le nombre d'occupants.
        # Ces valeurs servent à rendre le simulateur plus réaliste.
        self.consommation_occupants_kwh_an = {
            1: 1000,
            2: 1800,
            3: 2500,
            4: 3200,
            5: 3900
        }

        # Tarif utilisé pour la consommation générale des occupants.
        # Même si le chauffage est au gaz ou au mazout, les appareils restent surtout électriques.
        self.tarif_occupants_kwh = 0.10

    def obtenir_tarif_kwh(self):
        """
        Retourne le tarif selon le type de chauffage.
        """
        return self.tarifs_kwh.get(self.type_chauffage, 0.10)

    def obtenir_rendement(self):
        """
        Retourne le rendement selon le type de chauffage.
        """
        return self.rendements.get(self.type_chauffage, 1.0)

    def calculer_besoin_thermique_annuel_kwh(self):
        """
        Convertit la perte thermique totale en besoin thermique annuel.
        """
        besoin_thermique = (self.perte_totale_watts * self.heures_chauffage_par_an) / 1000
        return besoin_thermique

    def calculer_consommation_chauffage_annuelle_kwh(self):
        """
        Calcule la consommation annuelle liée au chauffage.
        """
        besoin_thermique = self.calculer_besoin_thermique_annuel_kwh()
        rendement = self.obtenir_rendement()

        if rendement <= 0:
            return 0.0

        consommation_chauffage = besoin_thermique / rendement
        return consommation_chauffage

    def calculer_consommation_occupants_annuelle_kwh(self):
        """
        Calcule la consommation annuelle liée aux occupants.
        """
        if self.nb_occupants in self.consommation_occupants_kwh_an:
            return self.consommation_occupants_kwh_an[self.nb_occupants]

        # Sécurité si un jour on accepte plus que 5 occupants.
        consommation_5_occupants = self.consommation_occupants_kwh_an[5]
        occupants_supplementaires = self.nb_occupants - 5

        return consommation_5_occupants + occupants_supplementaires * 700

    def calculer_consommation_facturee_annuelle_kwh(self):
        """
        Calcule la consommation totale annuelle :
        chauffage + occupants.
        """
        consommation_chauffage = self.calculer_consommation_chauffage_annuelle_kwh()
        consommation_occupants = self.calculer_consommation_occupants_annuelle_kwh()

        consommation_totale = consommation_chauffage + consommation_occupants
        return consommation_totale

    def calculer_cout_chauffage_annuel(self):
        """
        Calcule le coût annuel lié au chauffage.
        """
        consommation_chauffage = self.calculer_consommation_chauffage_annuelle_kwh()
        tarif_chauffage = self.obtenir_tarif_kwh()

        cout_chauffage = consommation_chauffage * tarif_chauffage
        return cout_chauffage

    def calculer_cout_occupants_annuel(self):
        """
        Calcule le coût annuel lié aux occupants.
        """
        consommation_occupants = self.calculer_consommation_occupants_annuelle_kwh()

        cout_occupants = consommation_occupants * self.tarif_occupants_kwh
        return cout_occupants

    def calculer_cout_annuel(self):
        """
        Calcule le coût annuel total :
        coût chauffage + coût occupants.
        """
        cout_chauffage = self.calculer_cout_chauffage_annuel()
        cout_occupants = self.calculer_cout_occupants_annuel()

        cout_total = cout_chauffage + cout_occupants
        return cout_total

    def calculer_resultats(self):
        """
        Retourne un dictionnaire avec les résultats.
        """
        besoin_thermique = self.calculer_besoin_thermique_annuel_kwh()

        consommation_chauffage = self.calculer_consommation_chauffage_annuelle_kwh()
        consommation_occupants = self.calculer_consommation_occupants_annuelle_kwh()
        consommation_totale = self.calculer_consommation_facturee_annuelle_kwh()

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

    def comparer_avec_perte_optimisee(self, perte_optimisee_watts):
        """
        Compare le coût actuel avec une perte thermique optimisée.
        """
        perte_optimisee_watts = self.valider_perte_totale_watts(perte_optimisee_watts)

        calcul_optimise = CalculCout(
            perte_totale_watts=perte_optimisee_watts,
            type_chauffage=self.type_chauffage,
            heures_chauffage_par_an=self.heures_chauffage_par_an,
            nb_occupants=self.nb_occupants
        )

        resultats_actuels = self.calculer_resultats()
        resultats_optimises = calcul_optimise.calculer_resultats()

        economies = resultats_actuels["cout_annuel"] - resultats_optimises["cout_annuel"]

        return {
            "actuel": resultats_actuels,
            "optimise": resultats_optimises,
            "economies_annuelles": round(economies, 2)
        }

    # Méthodes de validation

    def valider_perte_totale_watts(self, perte_totale_watts):
        try:
            perte_totale_watts = float(perte_totale_watts)
        except (TypeError, ValueError):
            return 0.0

        if perte_totale_watts < 0:
            return 0.0

        return perte_totale_watts

    def valider_heures_chauffage_par_an(self, heures_chauffage_par_an):
        try:
            heures_chauffage_par_an = float(heures_chauffage_par_an)
        except (TypeError, ValueError):
            return 4320

        if heures_chauffage_par_an < 0:
            return 4320

        return heures_chauffage_par_an

    def valider_nb_occupants(self, nb_occupants):
        try:
            nb_occupants = int(nb_occupants)
        except (TypeError, ValueError):
            return 1

        if nb_occupants < 1:
            return 1

        return nb_occupants

    def valider_type_chauffage(self, type_chauffage):
        type_chauffage = str(type_chauffage).strip().lower()

        if type_chauffage == "electrique":
            return "chauffage_electrique"

        if type_chauffage == "électrique":
            return "chauffage_electrique"

        if type_chauffage == "gaz":
            return "chauffage_gaz"

        if type_chauffage == "thermopompe":
            return "thermopompe"

        if type_chauffage == "mazout":
            return "chauffage_mazout"

        types_valides = [
            "chauffage_electrique",
            "chauffage_gaz",
            "thermopompe",
            "chauffage_mazout"
        ]

        if type_chauffage not in types_valides:
            return "chauffage_electrique"

        return type_chauffage