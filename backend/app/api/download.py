from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse
from app.config import config
from app.logger import logger
from pathlib import Path

router = APIRouter()

@router.get("/download/{job_id}/{filename}")
def download_file(job_id: str, filename: str):
    """
    Permet de télécharger un fichier PDF traité spécifique dans le job.
    """
    file_path = config.OCR_ROOT / job_id / config.OUTPUT_SUBDIR / filename

    logger.info(f"[{job_id}] 📥 Requête de téléchargement pour le fichier : {filename}")

    if not file_path.exists() or not file_path.is_file():
        logger.warning(f"[{job_id}] ❌ Fichier introuvable : {file_path}")
        raise HTTPException(status_code=404, detail="Fichier non trouvé")

    logger.info(f"[{job_id}] ✅ Fichier trouvé : {file_path}")
    return FileResponse(
        path=str(file_path),
        filename=filename,
        media_type="application/pdf"
    )
