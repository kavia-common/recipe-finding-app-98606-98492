import os, requests

def test_health():
    port = os.environ.get('PORT','8000')
    url = f'http://127.0.0.1:{port}/health'
    r = requests.get(url, timeout=5)
    assert r.status_code == 200
    assert r.json().get('status') == 'ok'
