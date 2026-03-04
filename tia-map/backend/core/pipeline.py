from __future__ import annotations

from pathlib import Path

from .analyzer import build_call_edges
from .builder import build_graph_payload
from .parser import parse_blocks_from_export
from .resolver import build_db_instance_edges


def run_graph_pipeline(export_root: Path) -> dict:
    blocks = parse_blocks_from_export(export_root)
    call_edges, external_nodes = build_call_edges(blocks)
    db_edges, db_nodes = build_db_instance_edges(blocks)
    return build_graph_payload(blocks, call_edges, db_edges, external_nodes, db_nodes)

