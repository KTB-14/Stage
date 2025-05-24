#!/bin/bash

echo "==================================================================="
echo "          SCRIPT DE GESTION DE NGINX POUR PDFTOOLS"
echo "==================================================================="

NGINX_CONF_SRC="/opt/pdftools/install/nginx/pdftools.conf"
NGINX_CONF_DEST="/etc/nginx/sites-available/pdftools"
NGINX_SYMLINK="/etc/nginx/sites-enabled/pdftools"

echo
echo "1) Installer et activer Nginx pour PDFTools"
echo "2) Désinstaller complètement Nginx + config PDFTools"
echo "3) Quitter"
echo
read -p "Choix [1-3] : " choice

case "$choice" in
  1)
    echo
    echo "----------------------------------------------------------------------"
    echo "           [1/2] INSTALLATION ET CONFIGURATION DE NGINX              "
    echo "----------------------------------------------------------------------"

    echo "Installation de Nginx si nécessaire..."
    sudo apt install -y nginx

    echo "Copie de la configuration PDFTools..."
    if [ -f "$NGINX_CONF_SRC" ]; then
      sudo cp "$NGINX_CONF_SRC" "$NGINX_CONF_DEST"
    else
      echo "Erreur : fichier introuvable à $NGINX_CONF_SRC"
      exit 1
    fi

    echo "Activation de la configuration..."
    if [ ! -L "$NGINX_SYMLINK" ]; then
      sudo ln -s "$NGINX_CONF_DEST" "$NGINX_SYMLINK"
    fi

    echo "Suppression de la configuration par défaut si elle existe..."
    if [ -L "/etc/nginx/sites-enabled/default" ]; then
      sudo rm /etc/nginx/sites-enabled/default
    fi

    echo "Test de configuration Nginx..."
    sudo nginx -t || exit 1

    echo "Redémarrage de Nginx..."
    sudo systemctl restart nginx

    if command -v ufw > /dev/null; then
      echo "Ouverture du pare-feu pour Nginx..."
      sudo ufw allow 'Nginx Full'
    fi

    echo
    echo "✅ Nginx est maintenant configuré pour PDFTools à http://<IP_DU_SERVEUR>/"
    echo
    ;;

  2)
    echo
    echo "----------------------------------------------------------------------"
    echo "           [2/2] DÉSINSTALLATION COMPLÈTE DE NGINX + CONFIG          "
    echo "----------------------------------------------------------------------"

    echo "Suppression des fichiers de configuration PDFTools..."
    sudo rm -f "$NGINX_SYMLINK"
    sudo rm -f "$NGINX_CONF_DEST"

    echo "Suppression des fichiers éventuels dans conf.d..."
    sudo rm -f /etc/nginx/conf.d/pdftools.conf

    echo "Purge de Nginx..."
    sudo apt purge -y nginx nginx-common
    sudo apt autoremove -y

    echo "Vérification que Nginx ne tourne plus..."
    sudo systemctl stop nginx 2>/dev/null
    sudo systemctl disable nginx 2>/dev/null

    echo
    echo "✅ Nginx et toute configuration associée à PDFTools ont été supprimés"
    echo
    ;;

  3)
    echo "Sortie."
    exit 0
    ;;

  *)
    echo "Option invalide."
    ;;
esac
