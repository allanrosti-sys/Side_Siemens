from __future__ import annotations

from pathlib import Path

from fastapi import APIRouter, HTTPException

from core.pipeline import run_graph_pipeline

router = APIRouter(prefix="/api", tags=["graph"])


@router.get("/graph/{project_id}")
def get_graph(project_id: str) -> dict:
    """
    Retorna o payload de grafo (nodes + edges) para o projeto solicitado.
    Nesta fase inicial, usamos os XMLs locais exportados como base padrao.
    """
    current_dir = Path.cwd()
    backend_dir = Path(__file__).resolve().parents[2]
    repo_root = Path(__file__).resolve().parents[4]
    candidates = [
        current_dir / "Logs" / "ControlModules_Export",
        backend_dir / "Logs" / "ControlModules_Export",
        repo_root / "Logs" / "ControlModules_Export",
    ]
    export_root = next((path.resolve() for path in candidates if path.exists()), None)
    if export_root is None:
        raise HTTPException(status_code=404, detail="Pasta de exportacao nao encontrada.")

    payload = run_graph_pipeline(export_root)
    payload["projectId"] = project_id
    payload["source"] = str(export_root)
    return payload
