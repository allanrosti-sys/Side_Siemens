from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional


@dataclass
class CallOccurrence:
    """Representa uma chamada encontrada no XML exportado do TIA."""

    call_name: str
    call_type: str
    instance_name: Optional[str] = None
    instance_db_number: Optional[int] = None


@dataclass
class Block:
    """Representa um bloco (OB/FB/FC) parseado do export XML."""

    id: str
    name: str
    block_type: str
    group_path: str
    source_file: Path
    raw_xml: str
    constant_name: Optional[str] = None
    calls: list[CallOccurrence] = field(default_factory=list)


@dataclass
class Edge:
    """Aresta do grafo de arquitetura (chamada, dependencia de DB etc.)."""

    source: str
    target: str
    kind: str
    label: str
    metadata: dict = field(default_factory=dict)

