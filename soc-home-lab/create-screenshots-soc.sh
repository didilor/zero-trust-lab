#!/bin/bash
# Arborescence screenshots/ pour le repo soc-home-lab
# Usage : à lancer depuis la racine du repo soc-home-lab

set -e
echo "Création de l'arborescence screenshots/ (SOC)..."

mkdir -p screenshots/ad
mkdir -p screenshots/wazuh
mkdir -p screenshots/opnsense
mkdir -p screenshots/glpi
mkdir -p screenshots/attack-scenarios
mkdir -p screenshots/troubleshooting

find screenshots -type d -exec touch {}/.gitkeep \;

echo "Arborescence créée :"
find screenshots -type d | sort
echo ""
echo "Pense à supprimer les .gitkeep au fur et à mesure que tu ajoutes de vraies captures."
