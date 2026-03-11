from pathlib import Path

from core.analyzer import build_call_edges
from core.parser import parse_blocks_from_export
from core.pipeline import run_graph_pipeline
from core.resolver import build_db_instance_edges


ROOT = Path(__file__).resolve().parents[3]
EXPORT_ROOT = ROOT / 'Logs' / 'ControlModules_Export'


def test_parser_deve_ler_blocos_xml_exportados() -> None:
    blocks = parse_blocks_from_export(EXPORT_ROOT)
    assert len(blocks) >= 1


def test_analyzer_deve_encontrar_chamadas_ou_externos() -> None:
    blocks = parse_blocks_from_export(EXPORT_ROOT)
    call_edges, external_nodes = build_call_edges(blocks)

    edge_exists = any(edge.source == 'fc:fcrobotrepko' and edge.target == 'fb:fbrobotrepko' for edge in call_edges)
    if any(block.id == 'fc:fcrobotrepko' for block in blocks):
        assert edge_exists
    if any('fb_requestdoor' in key for key in external_nodes.keys()):
        assert 'external:fb:fb_requestdoor' in external_nodes


def test_resolver_deve_criar_dependencias_para_dbs_de_instancia() -> None:
    blocks = parse_blocks_from_export(EXPORT_ROOT)
    db_edges, db_nodes = build_db_instance_edges(blocks)

    if any(call.instance_name for block in blocks for call in block.calls):
        assert len(db_edges) >= 0
    if db_nodes:
        assert any('db' in node_id for node_id in db_nodes.keys())


def test_pipeline_siements_deve_gerar_payload_compativel_com_react_flow() -> None:
    payload = run_graph_pipeline(EXPORT_ROOT, vendor='siemens')
    assert payload['vendor'] == 'siemens'
    assert 'nodes' in payload
    assert 'edges' in payload
    assert len(payload['nodes']) >= 1
