from fastapi.testclient import TestClient

from main import app

client = TestClient(app)


def test_health_endpoint() -> None:
    response = client.get('/api/health')
    assert response.status_code == 200
    data = response.json()
    assert data['status'] == 'ok'


def test_graph_endpoint() -> None:
    response = client.get('/api/graph/demo?vendor=siemens')
    assert response.status_code == 200
    data = response.json()
    assert data['projectId'] == 'demo'
    assert data['vendor'] == 'siemens'
    assert 'nodes' in data
    assert 'edges' in data
    assert len(data['nodes']) >= 1
