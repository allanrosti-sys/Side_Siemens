from __future__ import annotations

from pathlib import Path

from .analyzer import build_call_edges
from .builder import build_graph_payload
from .plc_parser import PLCParser
from .resolver import build_db_instance_edges
from .rockwell_parser import RockwellParser
from .siemens_parser import SiemensParser


def detect_vendor(source_path: Path) -> str:
    """Detecta o vendor com base na estrutura da origem e no cabecalho do arquivo."""
    if source_path.is_file() and source_path.suffix.lower() in ['.l5x', '.l5k']:
        return 'rockwell'

    all_candidates: list[Path] = []
    if source_path.exists() and source_path.is_dir():
        l5x_candidates = sorted(source_path.rglob('*.l5x'))
        l5k_candidates = sorted(source_path.rglob('*.l5k'))
        all_candidates = l5x_candidates + l5k_candidates
    if all_candidates:
        header = all_candidates[0].read_text(encoding='utf-8', errors='ignore')[:4000]
        if 'RSLogix 5000' in header:
            return 'rockwell'

    return 'siemens'


def _build_parser(vendor: str) -> PLCParser:
    if vendor == 'rockwell':
        return RockwellParser()
    return SiemensParser()


def run_graph_pipeline(source_path: Path, vendor: str = 'auto') -> dict:
    effective_vendor = detect_vendor(source_path) if vendor == 'auto' else vendor
    parser = _build_parser(effective_vendor)
    blocks = parser.parse(source_path)
    call_edges, external_nodes = build_call_edges(blocks)
    db_edges, db_nodes = build_db_instance_edges(blocks) if effective_vendor == 'siemens' else ([], {})
    payload = build_graph_payload(blocks, call_edges, db_edges, external_nodes, db_nodes)
    payload['vendor'] = effective_vendor
    return payload
