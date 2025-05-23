from fastapi import APIRouter, HTTPException
from app.models.job import StatusOut, JobStatus
from celery.result import AsyncResult
from worker.tasks import celery_app
from app.config import config
from app.logger import logger
from pathlib import Path
import json

router = APIRouter()

@router.get("/status/{job_id}", response_model=StatusOut)
def get_status(job_id: str):
    logger.info(f"[{job_id}] 🔍 Requête de statut reçue")

    result = AsyncResult(job_id, app=celery_app)
    celery_state = result.state.lower()

    try:
        status = JobStatus(celery_state)
        logger.info(f"[{job_id}] ✅ Statut Celery reconnu : {status}")
        return StatusOut(
            job_id=job_id,
            status=status,
            details=str(result.info) if result.info else None,
            files=_get_output_files(job_id) if status == JobStatus.done else None
        )
    except ValueError:
        logger.info(f"[{job_id}] ⚠️ Statut Celery inconnu ou terminé – fallback vers status.json")

    status_path = config.OCR_ROOT / job_id / config.STATUS_FILENAME
    if status_path.exists():
        try:
            with open(status_path, "r", encoding="utf-8") as f:
                data = json.load(f)

            files = _get_output_files(job_id)
            logger.info(f"[{job_id}] 📄 Lecture réussie de status.json")

            return StatusOut(
                job_id=job_id,
                status=JobStatus(data.get("status", "unknown")),
                details=data.get("details"),
                files=files
            )
        except Exception as e:
            logger.exception(f"[{job_id}] ❌ Erreur lecture status.json : {e}")
            raise HTTPException(status_code=500, detail=f"Erreur lecture status.json : {str(e)}")

    logger.warning(f"[{job_id}] ❌ Aucune info de statut trouvée")
    raise HTTPException(status_code=404, detail="Job non trouvé")


def _get_output_files(job_id: str):
    output_dir = config.OCR_ROOT / job_id / config.OUTPUT_SUBDIR
    if not output_dir.exists():
        return []
    return sorted([f.name for f in output_dir.glob("*.pdf") if f.is_file()])
