# Lémuriens

## Description

Dépot du projet TER **"Capteurs et lémuriens"** de Licence 3, encadré par Éric Bourreau.
Ce projet a pour but l'installation et la gestion de capteurs ***Libelium ©*** dans l'animalerie de l'université des sciences de Montpellier simplifiant ainsi la gestion de celle-ci.

## Prérequis

La programmation des capteur nécessite l’environnement [***Libelium ©***](http://www.libelium.com/development/waspmote/sdk_applications/).
Cet IDE permet de télé-transférer le code executable dans le Waspmote à condition que celui-ci soit allumé (via les deux interupteur à coté du connecteur mini-USB) et connecté.
L'IDE ne dispose pas d'***intellisence*** , par conséquent il faudra se référer à la [documentation](http://www.libelium.com/api/waspmote/html/) ainsi qu'aux divers exemples fournis dans l'IDE.

## Notes

Cerains buggs natifs à la librairie (tout du moins à sa version actuelle) ralentissent considérablement le débuguage, parmi ces problèmes on peut noter :

* L'impossibilité d'afficher correctement quoi que ce soit via le moniteur sériel USB (valable pour Windows, à tester pour Linux & Mac OS).
