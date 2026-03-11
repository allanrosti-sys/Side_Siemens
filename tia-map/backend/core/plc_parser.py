from __future__ import annotations

from abc import ABC, abstractmethod
from pathlib import Path

from .models import Block


class PLCParser(ABC):
    """Contrato base para qualquer parser de PLC suportado pela plataforma."""

    vendor: str

    @abstractmethod
    def parse(self, source_path: Path) -> list[Block]:
        """Converte a origem do vendor para a estrutura normalizada de blocos."""
