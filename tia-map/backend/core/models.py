from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional


@dataclass
class CallOccurrence:
    """Representa uma chamada encontrada no fonte normalizado do PLC."""

    call_name: str
    call_type: str
    instance_name: Optional[str] = None
    instance_db_number: Optional[int] = None
    metadata: dict[str, object] = field(default_factory=dict)


@dataclass
class Block:
    """Representa um elemento logico normalizado, independente do vendor."""

    id: str
    name: str
    block_type: str
    group_path: str
    source_file: Path
    raw_xml: str
    vendor: str = 'siemens'
    container_name: Optional[str] = None
    constant_name: Optional[str] = None
    calls: list[CallOccurrence] = field(default_factory=list)


@dataclass
class Edge:
    """Aresta do grafo de arquitetura (chamada, dependencia, hierarquia etc.)."""

    source: str
    target: str
    kind: str
    label: str
    metadata: dict = field(default_factory=dict)
