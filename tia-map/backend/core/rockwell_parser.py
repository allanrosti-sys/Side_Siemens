from __future__ import annotations

import re
import xml.etree.ElementTree as ET
from html import unescape
from pathlib import Path

from .plc_parser import PLCParser
from .models import Block, CallOccurrence


def _read_text(path: Path) -> str:
    return path.read_text(encoding='utf-8', errors='ignore')


def _pick_rockwell_source(source_path: Path) -> Path | None:
    """Seleciona um arquivo Rockwell valido a partir de um arquivo ou diretorio."""
    if source_path.is_file() and source_path.suffix.lower() in {'.l5k', '.l5x'}:
        return source_path

    if source_path.is_dir():
        l5k = sorted(source_path.rglob('*.l5k'))
        if l5k:
            return l5k[0]
        l5x = sorted(source_path.rglob('*.l5x'))
        if l5x:
            return l5x[0]

    return None


def parse_l5k_source(source_path: Path) -> list[Block]:
    """Extrai TASK/PROGRAM/ROUTINE e chamadas JSR de um L5K."""
    blocks: list[Block] = []

    task_pattern = re.compile(r'^\s*TASK\s+([\w-]+)\b')
    prog_pattern = re.compile(r'^\s*PROGRAM\s+([\w-]+)\b')
    rout_pattern = re.compile(r'^\s*ROUTINE\s+([\w-]+)\b')
    end_routine_pattern = re.compile(r'^\s*END_ROUTINE\b')
    jsr_pattern = re.compile(r'JSR\s*\(\s*([\w-]+)', re.IGNORECASE)

    current_program: Block | None = None
    current_routine: Block | None = None
    routine_lines: list[str] = []

    for line in _read_text(source_path).splitlines():
        task_match = task_pattern.match(line)
        if task_match:
            task_name = task_match.group(1)
            blocks.append(
                Block(
                    id=f'TASK.{task_name}',
                    name=task_name,
                    block_type='Task',
                    group_path='',
                    source_file=source_path,
                    raw_xml='',
                    vendor='rockwell',
                    container_name=None,
                )
            )
            continue

        prog_match = prog_pattern.match(line)
        if prog_match:
            program_name = prog_match.group(1)
            current_program = Block(
                id=f'PROG.{program_name}',
                name=program_name,
                block_type='Program',
                group_path='',
                source_file=source_path,
                raw_xml='',
                vendor='rockwell',
                container_name=None,
            )
            blocks.append(current_program)
            current_routine = None
            routine_lines = []
            continue

        rout_match = rout_pattern.match(line)
        if rout_match:
            routine_name = rout_match.group(1)
            container = current_program.name if current_program else 'Global'
            current_routine = Block(
                id=f'PROG.{container}.{routine_name}',
                name=routine_name,
                block_type='Routine',
                group_path=container,
                source_file=source_path,
                raw_xml='',
                vendor='rockwell',
                container_name=container if current_program else None,
            )
            blocks.append(current_routine)
            routine_lines = []
            continue

        if current_routine:
            routine_lines.append(line)
            for jsr_match in jsr_pattern.finditer(line):
                target_routine = jsr_match.group(1)
                current_routine.calls.append(
                    CallOccurrence(call_name=target_routine, call_type='Routine')
                )

            if end_routine_pattern.match(line):
                current_routine.raw_xml = '\n'.join(routine_lines).strip()
                current_routine = None
                routine_lines = []

    return blocks


def _extract_text(element: ET.Element | None) -> str:
    if element is None or element.text is None:
        return ''
    # Decodifica entidades HTML para manter a logica legivel.
    return unescape(element.text).strip()


def parse_l5x_source(source_path: Path) -> list[Block]:
    """Extrai Tasks/Programs/Routines e chamadas JSR de um L5X."""
    blocks: list[Block] = []

    xml_text = _read_text(source_path)
    root = ET.fromstring(xml_text)

    controller = root.find('.//Controller')
    if controller is None:
        return blocks

    for task in controller.findall('.//Tasks/Task'):
        task_name = task.get('Name') or 'Task'
        blocks.append(
            Block(
                id=f'TASK.{task_name}',
                name=task_name,
                block_type='Task',
                group_path='',
                source_file=source_path,
                raw_xml='',
                vendor='rockwell',
                container_name=None,
            )
        )

    for program in controller.findall('.//Programs/Program'):
        program_name = program.get('Name') or 'Program'
        program_block = Block(
            id=f'PROG.{program_name}',
            name=program_name,
            block_type='MainProgram',
            group_path='',
            source_file=source_path,
            raw_xml='',
            vendor='rockwell',
            container_name=None,
        )
        blocks.append(program_block)

        for routine in program.findall('.//Routines/Routine'):
            routine_name = routine.get('Name') or 'Routine'
            routine_block = Block(
                id=f'PROG.{program_name}.{routine_name}',
                name=routine_name,
                block_type='Routine',
                group_path=program_name,
                source_file=source_path,
                raw_xml='',
                vendor='rockwell',
                container_name=program_name,
            )

            texts: list[str] = []
            for rung in routine.findall('.//Rung'):
                text_el = rung.find('Text')
                if text_el is not None:
                    texts.append(_extract_text(text_el))

            for line in routine.findall('.//STContent/Line'):
                texts.append(_extract_text(line))

            routine_text = '\n'.join([t for t in texts if t])
            routine_block.raw_xml = routine_text

            jsr_pattern = re.compile(r'JSR\s*\(\s*([\w-]+)', re.IGNORECASE)
            for jsr_match in jsr_pattern.finditer(routine_text):
                routine_block.calls.append(
                    CallOccurrence(call_name=jsr_match.group(1), call_type='Routine')
                )

            blocks.append(routine_block)

    return blocks


class RockwellParser(PLCParser):
    """Parser multi-formato Rockwell (L5K e L5X)."""

    vendor: str = 'rockwell'

    def parse(self, source_path: Path) -> list[Block]:
        rockwell_source = _pick_rockwell_source(source_path)
        if rockwell_source is None:
            return []

        if rockwell_source.suffix.lower() == '.l5x':
            return parse_l5x_source(rockwell_source)

        return parse_l5k_source(rockwell_source)
