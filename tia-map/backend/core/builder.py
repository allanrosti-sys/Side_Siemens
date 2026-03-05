from __future__ import annotations

import re

from .models import Block, Edge


TYPE_COLORS = {
    "OB": "#7e57c2",
    "FB": "#1e88e5",
    "FC": "#2e7d32",
    "DB": "#9e9e9e",
    "EXTERNAL": "#616161",
}


def _extract_code_preview(raw_xml: str) -> str:
    """Retorna um trecho legivel para o painel lateral do frontend."""
    st_match = re.search(r"<StructuredText>(.*?)</StructuredText>", raw_xml, re.IGNORECASE | re.DOTALL)
    if st_match:
        snippet = st_match.group(1).strip()
        if snippet:
            return snippet

    source_match = re.search(r"<Source>(.*?)</Source>", raw_xml, re.IGNORECASE | re.DOTALL)
    if source_match:
        snippet = source_match.group(1).strip()
        if snippet:
            return snippet

    lines = [line.rstrip() for line in raw_xml.splitlines() if line.strip()]
    preview = "\n".join(lines[:120])
    if len(lines) > 120:
        preview += "\n..."
    return preview


def _node_payload(
    node_id: str,
    label: str,
    node_type: str,
    group_path: str = "",
    code: str = "",
    comment: str = "",
) -> dict:
    return {
        "id": node_id,
        "type": "default",
        "data": {
            "label": label,
            "blockType": node_type,
            "groupPath": group_path,
            "color": TYPE_COLORS.get(node_type, "#455a64"),
            "code": code,
            "comment": comment,
            "author": "TIA Openness",
            "version": "1.0",
        },
        "position": {"x": 0, "y": 0},
    }


def build_graph_payload(
    blocks: list[Block],
    call_edges: list[Edge],
    db_edges: list[Edge],
    external_nodes: dict[str, str],
    db_nodes: dict[str, str],
) -> dict:
    nodes = []
    edges = []

    for block in blocks:
        label = f"{block.block_type} {block.name}"
        code_preview = _extract_code_preview(block.raw_xml)
        comment = f"Origem: {block.source_file.name}"
        nodes.append(
            _node_payload(
                block.id,
                label,
                block.block_type,
                block.group_path,
                code_preview,
                comment,
            )
        )

    for node_id, external_name in external_nodes.items():
        nodes.append(_node_payload(node_id, f"EXTERNO {external_name}", "EXTERNAL", comment="Bloco chamado e nao encontrado no export."))

    for node_id, db_label in db_nodes.items():
        nodes.append(_node_payload(node_id, db_label, "DB", comment="DB de instancia detectado nas chamadas de FB."))

    for index, edge in enumerate(call_edges + db_edges, start=1):
        edges.append(
            {
                "id": f"e{index}",
                "source": edge.source,
                "target": edge.target,
                "label": edge.label,
                "data": {"kind": edge.kind, **edge.metadata},
            }
        )

    return {"nodes": nodes, "edges": edges}
