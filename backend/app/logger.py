import logging
from logging.handlers import RotatingFileHandler
from pathlib import Path
from app.config import config

# Création du dossier de log si inexistant
config.LOG_DIR.mkdir(parents=True, exist_ok=True)

# Initialisation du logger global
logger = logging.getLogger("pdf_service_logger")
logger.setLevel(getattr(logging, config.LOG_LEVEL.upper(), logging.INFO))

# === Handler : fichier rotatif ===
logfile = config.LOG_DIR / "ocr.log"
file_handler = RotatingFileHandler(
    filename=str(logfile),
    maxBytes=50 * 1024 * 1024,
    backupCount=5,
    encoding="utf-8"
)

# === Handler : console (optionnel mais recommandé)
console_handler = logging.StreamHandler()

# Format des logs
formatter = logging.Formatter("[%(asctime)s] %(levelname)s in %(module)s: %(message)s")
file_handler.setFormatter(formatter)
console_handler.setFormatter(formatter)

# Ajout des handlers
logger.addHandler(file_handler)
logger.addHandler(console_handler)

# Log de démarrage (utile pour confirmer le niveau utilisé)
logger.info(f"✅ Logger initialisé — Niveau : {config.LOG_LEVEL} — Fichier : {logfile}")
