from __future__ import annotations

from collections import defaultdict

from .models import Block, Edge


def _aliases_for_block(block: Block) -> set[str]:
    aliases: set[str] = set()

    def add(value: str | None) -> None:
        if value:
            aliases.add(value.lower())

    add(block.name)
    add(block.constant_name)
    add(block.source_file.stem)
    add(block.container_name)

    if block.container_name:
        add(f'{block.container_name}_{block.name}')
        add(f'{block.container_name}:{block.name}')

    for candidate in list(aliases):
        for prefix in ('fb_', 'fc_', 'ob_'):
            if candidate.startswith(prefix):
                add(candidate[len(prefix) :])

    return aliases


def _build_index(blocks: list[Block]) -> dict[str, list[Block]]:
    index: dict[str, list[Block]] = defaultdict(list)
    for block in blocks:
        for alias in _aliases_for_block(block):
            index[alias].append(block)
    return index


def _resolve_target(call_name: str, call_type: str, index: dict[str, list[Block]]) -> Block | None:
    candidates = index.get(call_name.lower(), [])
    if not candidates:
        return None

    typed = [block for block in candidates if block.block_type == call_type]
    if typed:
        return typed[0]
    return candidates[0]


def build_call_edges(blocks: list[Block]) -> tuple[list[Edge], dict[str, str]]:
    index = _build_index(blocks)
    edges: list[Edge] = []
    external_nodes: dict[str, str] = {}
    seen: set[tuple[str, str, str, str]] = set()

    for source_block in blocks:
        for call in source_block.calls:
            target_block = _resolve_target(call.call_name, call.call_type, index)
            if target_block is not None:
                target_id = target_block.id
                label = f'{call.call_type} {call.call_name}'
            else:
                target_id = f'external:{call.call_type}:{call.call_name}'.lower()
                label = f'EXTERNO {call.call_type} {call.call_name}'
                external_nodes[target_id] = call.call_name

            key = (source_block.id, target_id, 'call', label)
            if key in seen:
                continue
            seen.add(key)

            edges.append(
                Edge(
                    source=source_block.id,
                    target=target_id,
                    kind='call',
                    label=label,
                    metadata={
                        'call_name': call.call_name,
                        'call_type': call.call_type,
                        'instance_name': call.instance_name,
                        'instance_db_number': call.instance_db_number,
                        **call.metadata,
                    },
                )
            )

    return edges, external_nodes
