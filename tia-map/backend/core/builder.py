from __future__ import annotations

import html
import re
from xml.dom import minidom

from .models import Block, Edge


TYPE_COLORS = {
    'OB': '#7e57c2',
    'FB': '#1e88e5',
    'FC': '#2e7d32',
    'DB': '#9e9e9e',
    'EXTERNAL': '#616161',
    'Task': '#b71c1c',
    'MainProgram': '#c62828',
    'Routine': '#2e7d32',
    'AOI': '#1565c0',
    'TAG': '#757575',
}


def _normalize_whitespace(text: str) -> str:
    lines = [line.rstrip() for line in text.replace('\r\n', '\n').replace('\r', '\n').split('\n')]
    normalized = '\n'.join(lines).strip()
    return re.sub(r'\n{3,}', '\n\n', normalized)


def _extract_structured_text(raw_xml: str) -> str:
    """Converte trecho StructuredText (XML AST) para string legivel no painel."""
    st_block = re.search(r'<StructuredText\b[^>]*>(.*?)</StructuredText>', raw_xml, re.IGNORECASE | re.DOTALL)
    if not st_block:
        return ''

    body = st_block.group(1)
    body = re.sub(r'>\s+<', '><', body)
    body = re.sub(r'<NewLine\b[^>]*Num="(\d+)"[^>]*/>', lambda m: '\n' * max(1, int(m.group(1))), body, flags=re.IGNORECASE)
    body = re.sub(r'<Blank\b[^>]*Num="(\d+)"[^>]*/>', lambda m: ' ' * max(1, int(m.group(1))), body, flags=re.IGNORECASE)
    body = re.sub(r'<Token\b[^>]*Text="([^"]*)"[^>]*/>', lambda m: html.unescape(m.group(1)), body, flags=re.IGNORECASE)
    body = re.sub(r'<Component\b[^>]*Name="([^"]*)"[^>]*/>', lambda m: m.group(1), body, flags=re.IGNORECASE)
    body = re.sub(r'<ConstantValue\b[^>]*>(.*?)</ConstantValue>', lambda m: m.group(1), body, flags=re.IGNORECASE | re.DOTALL)
    body = re.sub(r'</?[^>]+>', '', body)
    body = html.unescape(body)
    return _normalize_whitespace(body)


def _pretty_xml_block(raw_xml: str) -> str:
    """Retorna XML formatado quando nao houver codigo legivel."""
    block_match = re.search(r'(<SW\.Blocks\.(?:OB|FB|FC)\b.*?</SW\.Blocks\.(?:OB|FB|FC)>)', raw_xml, re.IGNORECASE | re.DOTALL)
    xml_fragment = block_match.group(1) if block_match else raw_xml

    try:
        wrapped = f'<root>{xml_fragment}</root>'
        pretty = minidom.parseString(wrapped.encode('utf-8')).toprettyxml(indent='  ')
        lines = [line for line in pretty.splitlines() if line.strip() and line.strip() not in {'<root>', '</root>'}]
        return '\n'.join(lines[:260])
    except Exception:
        lines = [line.rstrip() for line in xml_fragment.splitlines() if line.strip()]
        return '\n'.join(lines[:220])


def _extract_code_preview(raw_xml: str) -> str:
    structured = _extract_structured_text(raw_xml)
    if structured:
        return structured

    source_match = re.search(r'<Source>(.*?)</Source>', raw_xml, re.IGNORECASE | re.DOTALL)
    if source_match:
        snippet = _normalize_whitespace(html.unescape(source_match.group(1)))
        if snippet:
            return snippet

    return _normalize_whitespace(_pretty_xml_block(raw_xml))


def _node_payload(node_id: str, label: str, node_type: str, vendor: str, group_path: str = '', code: str = '', comment: str = '') -> dict:
    author = 'TIA Openness' if vendor == 'siemens' else 'Rockwell L5X'
    return {
        'id': node_id,
        'type': 'default',
        'data': {
            'label': label,
            'blockType': node_type,
            'groupPath': group_path,
            'color': TYPE_COLORS.get(node_type, '#455a64'),
            'code': code,
            'comment': comment,
            'author': author,
            'version': '1.0',
            'vendor': vendor,
        },
        'position': {'x': 0, 'y': 0},
    }


def build_graph_payload(blocks: list[Block], call_edges: list[Edge], db_edges: list[Edge], external_nodes: dict[str, str], db_nodes: dict[str, str]) -> dict:
    nodes = []
    edges = []

    for block in blocks:
        label = f'{block.block_type} {block.name}'
        code_preview = _extract_code_preview(block.raw_xml)
        detail_parts = [f'Origem: {block.source_file.name}']
        if block.container_name:
            detail_parts.append(f'Container: {block.container_name}')
        nodes.append(_node_payload(block.id, label, block.block_type, block.vendor, block.group_path, code_preview, ' | '.join(detail_parts)))

    for node_id, external_name in external_nodes.items():
        nodes.append(_node_payload(node_id, f'EXTERNO {external_name}', 'EXTERNAL', 'siemens', comment='Elemento chamado e nao encontrado na origem.'))

    for node_id, db_label in db_nodes.items():
        nodes.append(_node_payload(node_id, db_label, 'DB', 'siemens', comment='DB de instancia detectado nas chamadas de FB.'))

    for index, edge in enumerate(call_edges + db_edges, start=1):
        edges.append(
            {
                'id': f'e{index}',
                'source': edge.source,
                'target': edge.target,
                'label': edge.label,
                'data': {'kind': edge.kind, **edge.metadata},
            }
        )

    return {'nodes': nodes, 'edges': edges}
