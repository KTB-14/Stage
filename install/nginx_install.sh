#!/bin/bash

echo "==================================================================="
echo "          SCRIPT DE GESTION DE NGINX POUR PDFTOOLS"
echo "==================================================================="

NGINX_CONF_SRC="/opt/pdftools/install/nginx/pdftools.conf"
NGINX_SITE_DEST=""
NGINX_SYMLINK=""

# Détection du type d’installation
if [ -d "/etc/nginx/sites-available" ]; then
  # Nginx installé via apt Ubuntu
  NGINX_SITE_DEST="/etc/nginx/sites-available/pdftools"
  NGINX_SYMLINK="/etc/nginx/sites-enabled/pdftools"
  NGINX_MODE="ubuntu"
else
  # Nginx installé via nginx.org
  NGINX_SITE_DEST="/etc/nginx/conf.d/pdftools.conf"
  NGINX_MODE="nginx.org"
fi

echo
echo "1) Installer et activer Nginx pour PDFTools"
echo "2) Désinstaller complètement Nginx et la configuration PDFTools"
echo "3) Quitter"
echo
read -p "Choix [1-3] : " choice

case "$choice" in
  1)
    echo
    echo "----------------------------------------------------------------------"
    echo "           INSTALLATION ET CONFIGURATION DE NGINX"
    echo "----------------------------------------------------------------------"
    echo

    echo "➤ Installation de Nginx si nécessaire..."
    sudo apt install -y nginx

    echo "➤ Copie de la configuration PDFTools..."
    if [ -f "$NGINX_CONF_SRC" ]; then
      sudo cp "$NGINX_CONF_SRC" "$NGINX_SITE_DEST"
      echo "✔️ Fichier copié vers : $NGINX_SITE_DEST"
    else
      echo "❌ Erreur : fichier introuvable à $NGINX_CONF_SRC"
      exit 1
    fi

    if [ "$NGINX_MODE" = "ubuntu" ]; then
      echo "➤ Activation via lien symbolique..."
      [ -L "$NGINX_SYMLINK" ] || sudo ln -s "$NGINX_SITE_DEST" "$NGINX_SYMLINK"
      echo "➤ Suppression du site par défaut..."
      sudo rm -f /etc/nginx/sites-enabled/default
    else
      echo "➤ Suppression de conf.d/default.conf si présent..."
      sudo rm -f /etc/nginx/conf.d/default.conf
    fi

    echo "➤ Test de la configuration Nginx..."
    sudo nginx -t || exit 1

    echo "➤ Redémarrage de Nginx..."
    sudo systemctl restart nginx

    if command -v ufw > /dev/null; then
      echo "➤ Ouverture du pare-feu pour Nginx..."
      sudo ufw allow 'Nginx Full' || echo "⚠️ Profil UFW non disponible"
    fi

    echo
    echo "✅ Nginx est maintenant configuré pour PDFTools à : http://<IP_DU_SERVEUR>/"
    echo
    ;;

  2)
    echo
    echo "----------------------------------------------------------------------"
    echo "       DÉSINSTALLATION COMPLÈTE DE NGINX ET CONFIGURATION"
    echo "----------------------------------------------------------------------"
    echo

    echo "➤ Suppression de la configuration PDFTools..."
    sudo rm -f "$NGINX_SITE_DEST"
    [ -n "$NGINX_SYMLINK" ] && sudo rm -f "$NGINX_SYMLINK"

    echo "➤ Purge de Nginx..."
    sudo apt purge -y nginx nginx-common
    sudo apt autoremove -y

    echo "➤ Désactivation du service..."
    sudo systemctl stop nginx 2>/dev/null
    sudo systemctl disable nginx 2>/dev/null

    echo
    echo "✅ Nginx et la configuration PDFTools ont été supprimés."
    echo
    ;;

  3)
    echo "Sortie."
    exit 0
    ;;

  *)
    echo "❌ Option invalide."
    ;;
esac
