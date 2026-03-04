from __future__ import annotations

import re

from .models import Block, Edge


def _extract_db_number_from_name(instance_name: str) -> int | None:
    digits = re.findall(r"\d+", instance_name)
    if not digits:
        return None
    return int(digits[0])


def build_db_instance_edges(blocks: list[Block]) -> tuple[list[Edge], dict[str, str]]:
    edges: list[Edge] = []
    db_nodes: dict[str, str] = {}
    seen: set[tuple[str, str, str]] = set()

    for source_block in blocks:
        for call in source_block.calls:
            if call.call_type != "FB":
                continue
            if not call.instance_name:
                continue

            instance_lower = call.instance_name.lower()
            if not instance_lower.startswith("db"):
                continue

            db_number = call.instance_db_number or _extract_db_number_from_name(call.instance_name)
            db_id = f"db:{call.instance_name}".lower()
            db_label = f"DB {call.instance_name}" if db_number is None else f"DB{db_number} ({call.instance_name})"
            db_nodes[db_id] = db_label

            key = (source_block.id, db_id, "instance_db")
            if key in seen:
                continue
            seen.add(key)

            edges.append(
                Edge(
                    source=source_block.id,
                    target=db_id,
                    kind="instance_db",
                    label="usa instancia DB",
                    metadata={
                        "call_name": call.call_name,
                        "instance_name": call.instance_name,
                        "db_number": db_number,
                    },
                )
            )

    return edges, db_nodes

