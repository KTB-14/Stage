#!/bin/bash

LOGFILE="/opt/pdftools/backend/logs/ocr.log"

echo "==================================================================="
echo "========== SCRIPT GLOBAL DE GESTION - PDFTOOLS ===================="
echo "==================================================================="
echo

# Fonction de log
to_log() {
  local message="$*"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" | tee -a "$LOGFILE"
}

# Vérifie si root
if [ "$EUID" -ne 0 ]; then
  echo "Ce script doit être exécuté avec sudo."
  exit 1
fi

# Menu principal
while true; do
  clear
  echo "===================== GESTION PDFTOOLS ====================="
  echo "1) Cloner et préparer le dépôt Git"
  echo "2) Installer les dépendances système"
  echo "3) Installer les dépendances Python"
  echo "4) Déployer les services systemd"
  echo "5) Désinstaller les services systemd"
  echo "6) Vérifier les services et tester l’API"
  echo "7) Quitter"
  echo "============================================================"
  read -p "Veuillez entrer un choix [1-7] : " choice

  case "$choice" in
    1)
      echo "----------------------------------------------------------------------"
      echo "           CLONAGE DU DEPOT PDFTOOLS                                 "
      echo "----------------------------------------------------------------------"
      cd /opt || exit 1
      if [ -d "/opt/pdftools" ]; then
        echo "Répertoire /opt/pdftools déjà existant. Suppression..."
        rm -rf /opt/pdftools
      fi
      git clone https://github.com/KTB-14/pdftools.git
      chown -R "$USER:$USER" /opt/pdftools
      cd /opt/pdftools/install || exit 1
      chmod +x *.sh
      echo "Clonage et préparation terminés."
      read -p "Appuyez sur Entrée pour continuer..."
      ;;
    2)
      to_log "Installation des dépendances système"
      bash /opt/pdftools/install/install_dependencies.sh
      to_log "Fin de l'installation des dépendances système"
      read -p "Appuyez sur Entrée pour continuer..."
      ;;
    3)
      to_log "Installation des dépendances Python"
      bash /opt/pdftools/install/install_python.sh
      to_log "Fin de l'installation des dépendances Python"
      read -p "Appuyez sur Entrée pour continuer..."
      ;;
    4)
      to_log "Déploiement des services systemd"
      bash /opt/pdftools/install/deploy_systemd.sh
      to_log "Fin du déploiement des services systemd"
      read -p "Appuyez sur Entrée pour continuer..."
      ;;
    5)
      to_log "Désinstallation des services systemd"
      bash /opt/pdftools/install/uninstall_systemd.sh
      to_log "Fin de la désinstallation des services systemd"
      read -p "Appuyez sur Entrée pour continuer..."
      ;;
    6)
      echo "----------------------------------------------------------------------"
      echo "        ÉTAT DES SERVICES ET TEST DE L'API                           "
      echo "----------------------------------------------------------------------"
      systemctl status ocr-api.service --no-pager
      systemctl status celery-ocr.service --no-pager
      systemctl list-timers --all | grep purge-ocr || echo "(Timer inactif)"
      echo
      echo "Test de l'API locale :"
      curl -s http://localhost:8000 && echo -e "\nRéponse reçue"
      echo "Ou test distant : curl http://<IP_DU_SERVEUR>:8000"
      read -p "Appuyez sur Entrée pour continuer..."
      ;;
    7)
      echo "----------------------------------------------------------------------"
      echo "               FIN DU SCRIPT GLOBAL - À BIENTÔT                      "
      echo "----------------------------------------------------------------------"
      to_log "Sortie du script de gestion PDFTools"
      exit 0
      ;;
    *)
      echo "Option invalide. Veuillez choisir un numéro entre 1 et 7."
      read -p "Appuyez sur Entrée pour réessayer..."
      ;;
  esac
done
