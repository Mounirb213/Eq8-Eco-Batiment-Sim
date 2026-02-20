class Chambre :
    def __int__(self, surface, aireMur, airePlancher, aireFenetre, airePlafond, isolation):
        self.surface = surface
        self.aireMur = aireMur
        self.airePlancher = airePlancher
        self.airFenetre = aireFenetre
        self.airePlafond = airePlafond
        self.isolation = isolation
    def calculPerteChaleur(self):
        return self