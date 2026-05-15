ECO-BAT-SIM




Mounir Boudria et 
Noé Berthezene






Projet d’Intégration 
En SIM






Table des matières
2.1. L’équipe
2.2. L’idée
2.3. L’utilité
2.4. L’innovation
2.5. Cas d’utilisation
2.6. Public cible 
2.7. Liens avec les autres manières
3.1. Technologies utilisées
3.2. Justification des choix
3.3. Défis et difficultés
4.1. Répartition des tâches
4.2. Échéancier
4.3. Analyse du projet 
4.4. Modélisation UML
4.5. Vues
5.1. Preuves d’exécution du projet
5.2. Difficultés rencontrées
5.3. Modifications de l’échéancier
5.4. Modification du UML
5.5. Perspectives
6. Conclusion


Session Hiver 2026
2.1 L’équipe
L’équipe d’EcoBatSim est composée de Mounir Boudria et Noé Berthézène. Mounir a la charge du développement backend et de la modélisation thermique, tandis que Noé supervise l’interface utilisateur et les tests de validation. 
________________________________________
2.2 L’idée
La problématique est : « Comment simuler la consommation énergétique d’un bâtiment ? ». Les objectifs incluent la création d’un outil interactif permettant d’analyser l’impact des matériaux, de l’isolation et du climat sur la thermographie du bâtiment.
________________________________________
2.3 L’utilité
L’utilité est de réduire la consommation énergétique des bâtiments, responsable de 30 % des émissions mondiales de CO₂. L’application permet aux personnes intéressées de tester virtuellement des scénarios d’optimisation (matériaux, type de chauffage, etc.).
________________________________________
2.4 L’innovation
Contrairement aux outils existants, souvent complexes et coûteux, EcoBatSim propose une interface interactive et gratuite. Sa valeur ajoutée réside dans l’intégration de données météorologiques en temps réel ou historique, offrant des prédictions personnalisées selon la localisation géographique (Montréal).
________________________________________
2.5 Cas d’utilisation
Les acteurs incluent les professionnels du bâtiment, les étudiants en sciences de l’ingénieur et les citoyens souhaitant réduire leur empreinte carbone.
________________________________________
2.6 Public cible
L’application s’adresse principalement aux étudiants. Elle est également adaptée aux particuliers souhaitant comprendre l’efficacité énergétique de leur logement. 
________________________________________
2.7 Liens avec les autres matières
EcoBatSim intègre des concepts clés de l’informatique, des mathématiques et des sciences (physique thermique). Cette interdisciplinarité renforce la pertinence du projet, en appliquant des théories académiques à un problème concret de société.
________________________________________

3.1 Technologies utilisées
Le projet repose sur Python pour le cœur de l’application, avec l’IDE PyCharm pour le développement. Git assure la collaboration et le suivi des versions. L’interface graphique est conçue avec Godot, offrant une expérience utilisateur moderne et réactive en 3D.
________________________________________
3.2 Justification des choix
Python a été choisi pour sa conception scientifique, essentielle pour un outil de simulation. Git permet une gestion efficace des modifications en équipe, et Godot offre une flexibilité pour créer des visualisations thermiques interactives sur un bâtiment 3D. Ces technologies, bien maîtrisées par l’équipe, assurent un équilibre entre performance et simplicité.
________________________________________
3.3 Défis et difficultés
L’un des défis majeurs a été l’apprentissage de la modélisation thermique sur Godot et le lien avec python, nécessitant des recherches approfondies en serveur local (Flask). De plus, l’intégration de données météorologiques en temps réel a posé des contraintes techniques liées aux API externes et à la gestion des erreurs réseau.
________________________________________
4.1 Répartition des tâches
Mounir s’occupe du développement des algorithmes de simulation et des tests unitaires, tandis que Noé conçoit l’interface utilisateur et les scénarios de test. Une coordination quotidienne via des réunions courtes permet d’ajuster les priorités et de résoudre les blocages en temps réel.
________________________________________
4.2 Échéancier
Un diagramme de Gantt détaillé structure le projet sur 6 semaines : analyse des besoins (semaine 1), développement backend (semaines 2-3), conception UI (semaine 3), tests (semaine 4) et documentation (semaine 5). 
________________________________________
4.3 Analyse du projet
Les enjeux incluent la précision des simulations et l’accessibilité de l’outil. Les contraintes techniques portent sur la limitation des ressources matérielles pour les calculs intensifs, tandis que les contraintes temporelles imposent une livraison rapide pour répondre aux besoins du cours.
________________________________________
4.4 Modélisation UML
Le diagramme de classes décrit les entités clés : Bâtiment, Matériau, Climat, et leurs relations. Cette modélisation permet de structurer la logique métier et d’anticiper les interactions entre les composants, facilitant ainsi le développement.
  
________________________________________
4.5 Vues
L’interface graphique présente des onglets pour configurer le bâtiment (matériaux, dimensions), visualiser les résultats sous forme de graphiques thermiques, et exporter des rapports détaillés. Une démo interactive montre l’impact des réglages en temps réel, renforçant l’expérience utilisateur.
 







5.1 Preuves d’exécutions du projet

 

 
 
5.2 Difficultés rencontrées
Nous avons rencontré de multiples difficultés à travers le projet. Par exemple, la modification de la vue 3D du bâtiment nous a obligé le déplacer sur Blender afin de faire les modifications nécessaires. De plus, nous avons eu divers problèmes pour connecter L’API entre le python et notre code/modèle 3D ce qui nous a grandement ralentis dans l’exécution de notre projet.







5.3 Modification de l’échéancier
Nous avons un peu modifié l’échéancier selon nos problèmes et nos priorités. Voici le diagramme Grant du projet : 
  








5.4 Modification de l’UML
 




5.5 Perspectives
Si nous avions eu plus de temps nous aurions trouvé une manière de permettre à l’utilisateur de mettre en place le bâtiment de son choix afin d’y faire les calculs voulu en plus de changer la localisation géographique météo afin d’avoir des résultats encore plus précis. Finalement, si nous avions eu plus de temps nous aurions poursuivi une amélioration globale de l’interface utilisateur afin d’ajouter des options de personnalisations.

6. Conclusion
EcoBatSim offre une solution innovante pour optimiser la performance énergétique des bâtiments, alliant simplicité et précision. Ce projet démontre l’impact potentiel de l’informatique sur les défis environnementaux actuels.

