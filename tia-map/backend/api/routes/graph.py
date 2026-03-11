from __future__ import annotations

import json
import os
from pathlib import Path

from fastapi import APIRouter, HTTPException, Query

from core.pipeline import detect_vendor, run_graph_pipeline

router = APIRouter(prefix='/api', tags=['graph'])


def _load_path_from_web_settings(repo_root: Path) -> str:
    settings_path = repo_root / 'Logs' / 'web_settings.json'
    if not settings_path.exists():
        return ''
    try:
        raw = settings_path.read_text(encoding='utf-8').lstrip('\ufeff')
        data = json.loads(raw)
        return str(data.get('tiaPath', '')).strip()
    except Exception:
        return ''


def _contains_rockwell(candidate: Path) -> bool:
    if candidate.is_file() and candidate.suffix.lower() in {'.l5x', '.l5k'}:
        return True
    if candidate.is_dir():
        return any(candidate.rglob('*.l5x')) or any(candidate.rglob('*.l5k'))
    return False


def _contains_siemens_export(candidate: Path) -> bool:
    if not candidate.exists() or not candidate.is_dir():
        return False
    return any(candidate.rglob('OB_*.xml')) or any(candidate.rglob('FB_*.xml')) or any(candidate.rglob('FC_*.xml'))


def _pick_existing(candidates: list[Path], vendor: str) -> Path | None:
    for candidate in candidates:
        if not candidate.exists():
            continue
        resolved = candidate.resolve()
        if vendor == 'rockwell' and _contains_rockwell(resolved):
            return resolved
        if vendor == 'siemens' and _contains_siemens_export(resolved):
            return resolved
        if vendor == 'auto' and (_contains_rockwell(resolved) or _contains_siemens_export(resolved)):
            return resolved
    return None


def _resolve_graph_source(vendor: str) -> tuple[Path | None, bool, bool]:
    env_path = (os.getenv('TIA_MAP_DATA_PATH') or '').strip()
    repo_root = Path(__file__).resolve().parents[4]
    settings_path = _load_path_from_web_settings(repo_root)
    # Preferir fontes que combinem com o vendor, sem ignorar a origem de ambiente.
    preferred_candidates: list[Path] = []
    base_paths = [p for p in [settings_path, env_path] if p]
    for raw_path in base_paths:
        base = Path(raw_path)
        preferred_candidates.extend([
            base / 'Logs' / 'ControlModules_Export',
            base / 'ControlModules_Export',
            base / 'Export',
            base,
        ])

    fallback_candidates = [
        repo_root / 'Logs' / 'ControlModules_Export',
        repo_root / 'ControlModules_Export',
        repo_root / 'Export',
        repo_root,
    ]

    resolved = _pick_existing(preferred_candidates, vendor) or _pick_existing(fallback_candidates, vendor)
    return resolved, bool(env_path), bool(settings_path)


@router.get('/graph/{project_id}')
def get_graph(project_id: str, vendor: str = Query(default='auto', pattern='^(auto|siemens|rockwell)$')) -> dict:
    """Retorna o payload de grafo padronizado, independente do vendor."""
    graph_source, from_env, from_settings = _resolve_graph_source(vendor)
    if graph_source is None:
        raise HTTPException(status_code=404, detail='Origem de dados nao encontrada para o vendor solicitado.')

    effective_vendor = detect_vendor(graph_source) if vendor == 'auto' else vendor
    payload = run_graph_pipeline(graph_source, vendor=effective_vendor)
    payload['projectId'] = project_id
    payload['source'] = str(graph_source)
    payload['sourceFromEnv'] = from_env
    payload['sourceFromSettings'] = from_settings
    return payload
