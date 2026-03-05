from __future__ import annotations

import json
import os
from pathlib import Path

from fastapi import APIRouter, HTTPException

from core.pipeline import run_graph_pipeline

router = APIRouter(prefix="/api", tags=["graph"])


def _load_path_from_web_settings(repo_root: Path) -> str:
    settings_path = repo_root / "Logs" / "web_settings.json"
    if not settings_path.exists():
        return ""
    try:
        raw = settings_path.read_text(encoding="utf-8").lstrip("\ufeff")
        data = json.loads(raw)
        return str(data.get("tiaPath", "")).strip()
    except Exception:
        return ""


def _resolve_export_root() -> tuple[Path | None, bool, bool]:
    env_path = (os.getenv("TIA_MAP_DATA_PATH") or "").strip()
    repo_root = Path(__file__).resolve().parents[4]
    settings_path = _load_path_from_web_settings(repo_root)

    # Prioridade de origem: Web settings (painel) -> variavel de ambiente (launcher).
    effective_path = settings_path or env_path

    preferred_candidates: list[Path] = []
    if effective_path:
        base = Path(effective_path)
        preferred_candidates.extend([
            base / "Logs" / "ControlModules_Export",
            base / "ControlModules_Export",
            base,
        ])

    current_dir = Path.cwd()
    backend_dir = Path(__file__).resolve().parents[2]
    fallback_candidates = [
        current_dir / "Logs" / "ControlModules_Export",
        backend_dir / "Logs" / "ControlModules_Export",
        repo_root / "Logs" / "ControlModules_Export",
    ]

    def pick(candidates: list[Path]) -> Path | None:
        best_existing = None
        for candidate in candidates:
            if not candidate.exists():
                continue
            if best_existing is None:
                best_existing = candidate.resolve()
            block_count = len(
                [
                    f
                    for f in candidate.rglob("*.xml")
                    if f.stem.startswith("OB_") or f.stem.startswith("FB_") or f.stem.startswith("FC_")
                ]
            )
            if block_count > 0:
                return candidate.resolve()
        return best_existing

    resolved = pick(preferred_candidates) or pick(fallback_candidates)
    return resolved, bool(env_path), bool(settings_path)


@router.get("/graph/{project_id}")
def get_graph(project_id: str) -> dict:
    """
    Retorna o payload de grafo (nodes + edges) para o projeto solicitado.
    A origem prioriza web_settings.json (UI) e depois TIA_MAP_DATA_PATH.
    """
    export_root, from_env, from_settings = _resolve_export_root()
    if export_root is None:
        raise HTTPException(status_code=404, detail="Pasta de exportacao nao encontrada.")

    payload = run_graph_pipeline(export_root)
    payload["projectId"] = project_id
    payload["source"] = str(export_root)
    payload["sourceFromEnv"] = from_env
    payload["sourceFromSettings"] = from_settings
    return payload
