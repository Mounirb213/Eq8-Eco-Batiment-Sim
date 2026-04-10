class CalculCout:
    """
    Sert à transformer les pertes thermiques en consommation énergétique annuelle et en coût annuel.

    - la perte thermique totale représente la puissance moyenne à compenser
    - on convertit cette puissance en énergie annuelle
    - on applique ensuite un tarif selon le type de chauffage

    Formules utilisées :
    besoin_thermique_annuel_kwh = (perte_totale_watts * heures_chauffage_par_an) / 1000

    consommation_facture_annuelle_kwh = besoin_thermique_annuel_kwh / rendement

    cout_annuel = consommation_facture_annuelle_kwh * tarif_kwh
    """

    def __init__(
        self,
        perte_totale_watts,
        type_chauffage="chauffage_electrique",
        heures_chauffage_par_an=4320
    ):
        self.perte_totale_watts = self.valider_perte_totale_watts(perte_totale_watts)
        self.type_chauffage = self.valider_type_chauffage(type_chauffage)
        self.heures_chauffage_par_an = self.valider_heures_chauffage_par_an(heures_chauffage_par_an)

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

    def calculer_consommation_facturee_annuelle_kwh(self):
        """
        Calcule la consommation réelle facturée selon le rendement du chauffage.
        """
        besoin_thermique = self.calculer_besoin_thermique_annuel_kwh()
        rendement = self.obtenir_rendement()

        if rendement <= 0:
            return 0.0

        consommation = besoin_thermique / rendement
        return consommation

    def calculer_cout_annuel(self):
        """
        Calcule le coût annuel en dollars.
        """
        consommation = self.calculer_consommation_facturee_annuelle_kwh()
        tarif = self.obtenir_tarif_kwh()

        cout = consommation * tarif
        return cout

    def calculer_resultats(self):
        """
        Retourne un dictionnaire avec les résultats.
        """
        besoin_thermique = self.calculer_besoin_thermique_annuel_kwh()
        consommation = self.calculer_consommation_facturee_annuelle_kwh()
        cout = self.calculer_cout_annuel()

        return {
            "type_chauffage": self.type_chauffage,
            "heures_chauffage_par_an": self.heures_chauffage_par_an,
            "tarif_kwh": round(self.obtenir_tarif_kwh(), 4),
            "rendement": round(self.obtenir_rendement(), 2),
            "besoin_thermique_annuel_kwh": round(besoin_thermique, 2),
            "consommation_energetique_kwh_an": round(consommation, 2),
            "cout_annuel": round(cout, 2)
        }

    def comparer_avec_perte_optimisee(self, perte_optimisee_watts):
        """
        Compare le coût actuel avec une perte thermique optimisée.
        Permet d'estimer les économies annuelles.
        """
        perte_optimisee_watts = self.valider_perte_totale_watts(perte_optimisee_watts)

        calcul_optimise = CalculCout(
            perte_totale_watts=perte_optimisee_watts,
            type_chauffage=self.type_chauffage,
            heures_chauffage_par_an=self.heures_chauffage_par_an
        )

        resultats_actuels = self.calculer_resultats()
        resultats_optimises = calcul_optimise.calculer_resultats()

        economies = resultats_actuels["cout_annuel"] - resultats_optimises["cout_annuel"]

        return {
            "actuel": resultats_actuels,
            "optimise": resultats_optimises,
            "economies_annuelles": round(economies, 2)
        }


    # Méthodes de validations

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

    def valider_type_chauffage(self, type_chauffage):
        type_chauffage = str(type_chauffage).strip().lower()

        if type_chauffage == "electrique":
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