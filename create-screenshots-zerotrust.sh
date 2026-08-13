#!/bin/bash
# Arborescence screenshots/ pour le repo zero-trust-lab (EYDIE-LAB)
# Usage : à lancer depuis la racine du repo zero-trust-lab

set -e
echo "Création de l'arborescence screenshots/ (Zero Trust)..."

mkdir -p screenshots/pki
mkdir -p screenshots/ad
mkdir -p screenshots/keycloak
mkdir -p screenshots/web
mkdir -p screenshots/client
mkdir -p screenshots/interconnexion

find screenshots -type d -exec touch {}/.gitkeep \;

echo "Arborescence créée :"
find screenshots -type d | sort
echo ""
echo "Pense à supprimer les .gitkeep au fur et à mesure que tu ajoutes de vraies captures."
