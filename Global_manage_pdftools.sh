#!/bin/bash

echo "==================================================================="
echo "         SCRIPT GLOBAL DE GESTION DU PROJET PDFTOOLS"
echo "==================================================================="

while true; do
  echo
  echo "1) Cloner et préparer le dépôt PDFTools"
  echo "2) Installer les dépendances système"
  echo "3) Installer les dépendances Python"
  echo "4) Déployer les services systemd"
  echo "5) Désinstaller les services systemd"
  echo "6) Vérifier les services"
  echo "7) Redémarrer tous les services"
  echo "8) Voir les logs du backend"
  echo "9) Purger les jobs expirés manuellement"
  echo "10) Supprimer tous les jobs OCR"
  echo "11) Lancer un test API"
  echo "12) Quitter"
  echo "13) Installer ou désinstaller la configuration Nginx uniquement"
  echo
  read -p "Choix [1-13] : " choice

  case "$choice" in
    1)
      echo "Clonage du dépôt..."
      cd /opt || exit
      sudo rm -rf pdftools
      sudo git clone https://github.com/KTB-14/pdftools.git
      sudo chown -R "$USER:$USER" /opt/pdftools
      chmod +x /opt/pdftools/install/*.sh
      echo "✅ Dépôt cloné."
      read -p "Appuyez sur Entrée pour continuer..."
      ;;
    2)
      bash /opt/pdftools/install/install_dependencies.sh
      read -p "Appuyez sur Entrée pour continuer..."
      ;;
    3)
      bash /opt/pdftools/install/install_python.sh
      read -p "Appuyez sur Entrée pour continuer..."
      ;;
    4)
      bash /opt/pdftools/install/deploy_systemd.sh
      read -p "Appuyez sur Entrée pour continuer..."
      ;;
    5)
      bash /opt/pdftools/install/uninstall_systemd.sh
      read -p "Appuyez sur Entrée pour continuer..."
      ;;
    6)
      systemctl status ocr-api.service --no-pager
      systemctl status celery-ocr.service --no-pager
      systemctl list-timers --all | grep purge-ocr || echo "(timer non actif)"
      read -p "Appuyez sur Entrée pour continuer..."
      ;;
    7)
      sudo systemctl restart ocr-api.service
      sudo systemctl restart celery-ocr.service
      echo "✅ Services redémarrés."
      read -p "Appuyez sur Entrée pour continuer..."
      ;;
    8)
      tail -n 50 /opt/pdftools/backend/logs/ocr.log
      read -p "Appuyez sur Entrée pour continuer..."
      ;;
    9)
      python3 /opt/pdftools/backend/scripts/purge_old_jobs.py
      read -p "Appuyez sur Entrée pour continuer..."
      ;;
    10)
      rm -rf /opt/pdftools/data/jobs/*
      echo "✅ Tous les jobs supprimés."
      read -p "Appuyez sur Entrée pour continuer..."
      ;;
    11)
      curl -s http://localhost/api/
      echo
      read -p "Appuyez sur Entrée pour continuer..."
      ;;
    12)
      if [ -f "/opt/pdftools/install/nginx_install.sh" ]; then
        bash /opt/pdftools/install/nginx_install.sh
      else
        echo "Erreur : /opt/pdftools/install/nginx_install.sh introuvable"
      fi
      read -p "Appuyez sur Entrée pour continuer..."
      ;;
    13)
      echo "Sortie."
      exit 0
      ;;
    *)
      echo "❌ Option invalide."
      ;;
  esac
done
