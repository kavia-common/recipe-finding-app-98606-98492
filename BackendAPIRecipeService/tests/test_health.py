import os
import requests

def test_health():
    port = int(os.environ.get('TEST_SERVER_PORT', '58435'))
    r = requests.get(f'http://127.0.0.1:{port}/health', timeout=5)
    assert r.status_code == 200
    assert r.json().get('status') == 'ok'
