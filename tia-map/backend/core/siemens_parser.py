from __future__ import annotations

import xml.etree.ElementTree as ET
from pathlib import Path

from .models import Block, CallOccurrence
from .plc_parser import PLCParser


class SiemensParser(PLCParser):
    """Parser dos XMLs exportados do TIA Portal."""

    vendor = 'siemens'

    def parse(self, source_path: Path) -> list[Block]:
        return parse_blocks_from_export(source_path)


def _strip_ns(tag: str) -> str:
    return tag.split('}')[-1]


def _normalize_block_type(raw_type: str) -> str:
    upper = raw_type.upper()
    if upper in {'OB', 'FB', 'FC'}:
        return upper
    return raw_type


def _safe_text(element: ET.Element | None) -> str | None:
    if element is None or element.text is None:
        return None
    return element.text.strip()


def _build_block_id(block_type: str, name: str) -> str:
    return f'{block_type}:{name}'.lower()


def _read_xml_text(xml_path: Path) -> str:
    """Le XML com tolerancia a codificacao para evitar corrupcao de texto."""
    raw_bytes = xml_path.read_bytes()
    for encoding in ('utf-8-sig', 'utf-16', 'utf-16-le', 'utf-16-be', 'cp1252', 'latin-1'):
        try:
            return raw_bytes.decode(encoding)
        except UnicodeDecodeError:
            continue
    return raw_bytes.decode('utf-8', errors='replace')


def parse_block_file(xml_path: Path, export_root: Path) -> Block:
    raw_xml = _read_xml_text(xml_path)
    root = ET.fromstring(raw_xml)

    block_type = ''
    for child in root:
        raw_tag = _strip_ns(child.tag)
        if raw_tag.startswith('SW.Blocks.'):
            block_type = _normalize_block_type(raw_tag.split('.')[-1])
            break

    if block_type not in {'OB', 'FB', 'FC'}:
        raise ValueError(f'Tipo de bloco nao suportado em {xml_path}: {block_type}')

    constant_name = None
    for element in root.iter():
        if _strip_ns(element.tag) == 'ConstantName':
            constant_name = _safe_text(element)
            if constant_name:
                break

    name_element = None
    for element in root.iter():
        if _strip_ns(element.tag) == 'Name':
            value = _safe_text(element)
            if value:
                name_element = value
                break

    block_name = constant_name or name_element or xml_path.stem
    group_path = str(xml_path.parent.relative_to(export_root)).replace('\\', '/')
    if group_path == '.':
        group_path = ''

    block = Block(
        id=_build_block_id(block_type, block_name),
        name=block_name,
        block_type=block_type,
        group_path=group_path,
        source_file=xml_path,
        raw_xml=raw_xml,
        vendor='siemens',
        constant_name=constant_name,
    )

    for element in root.iter():
        if _strip_ns(element.tag) != 'CallInfo':
            continue

        call_name = (element.attrib.get('Name') or '').strip()
        call_type = _normalize_block_type((element.attrib.get('BlockType') or '').strip())
        if not call_name:
            continue

        instance_name = None
        instance_db_number = None

        instance_element = next((child for child in element if _strip_ns(child.tag) == 'Instance'), None)
        if instance_element is not None:
            component_element = next((child for child in instance_element if _strip_ns(child.tag) == 'Component'), None)
            if component_element is not None:
                instance_name = (component_element.attrib.get('Name') or '').strip() or None

            address_element = next((child for child in instance_element if _strip_ns(child.tag) == 'Address'), None)
            if address_element is not None:
                db_number_text = (address_element.attrib.get('BlockNumber') or '').strip()
                if db_number_text.isdigit():
                    instance_db_number = int(db_number_text)

        block.calls.append(
            CallOccurrence(
                call_name=call_name,
                call_type=call_type,
                instance_name=instance_name,
                instance_db_number=instance_db_number,
            )
        )

    return block


def parse_blocks_from_export(export_root: Path) -> list[Block]:
    export_root = export_root.resolve()
    xml_files = sorted(export_root.rglob('*.xml'))
    blocks: list[Block] = []

    for xml_file in xml_files:
        try:
            block = parse_block_file(xml_file, export_root)
        except ValueError:
            continue
        blocks.append(block)

    return blocks
