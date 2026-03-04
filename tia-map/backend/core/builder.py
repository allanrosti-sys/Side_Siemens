from __future__ import annotations

from .models import Block, Edge


TYPE_COLORS = {
    "OB": "#7e57c2",
    "FB": "#1e88e5",
    "FC": "#2e7d32",
    "DB": "#9e9e9e",
    "EXTERNAL": "#616161",
}


def _node_payload(node_id: str, label: str, node_type: str, group_path: str = "") -> dict:
    return {
        "id": node_id,
        "type": "default",
        "data": {
            "label": label,
            "blockType": node_type,
            "groupPath": group_path,
            "color": TYPE_COLORS.get(node_type, "#455a64"),
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
        nodes.append(_node_payload(block.id, label, block.block_type, block.group_path))

    for node_id, external_name in external_nodes.items():
        nodes.append(_node_payload(node_id, f"EXTERNO {external_name}", "EXTERNAL"))

    for node_id, db_label in db_nodes.items():
        nodes.append(_node_payload(node_id, db_label, "DB"))

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

