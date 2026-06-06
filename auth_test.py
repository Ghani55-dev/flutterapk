import json
import urllib.request
import urllib.error
import uuid

base = 'https://incite-backend.onrender.com/api/v1'

def post(path, data, headers=None):
    url = base + path
    body = json.dumps(data).encode('utf-8')
    hdrs = {'Content-Type': 'application/json'}
    if headers:
        hdrs.update(headers)
    req = urllib.request.Request(url, data=body, headers=hdrs)
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            resp = r.read().decode('utf-8')
            print('STATUS', r.status)
            print(resp)
            return r.status, resp
    except urllib.error.HTTPError as e:
        try:
            body = e.read().decode('utf-8')
        except Exception:
            body = ''
        print('HTTP ERROR', e.code)
        print(body)
        return e.code, body
    except Exception as e:
        print('ERROR', e)
        return None, str(e)

if __name__ == '__main__':
    device_id = str(uuid.uuid4())
    user = {'email': 'testuser@incite.com', 'password': 'Test@123456', 'name': 'Test User', 'device_id': device_id}
    print('=== REGISTER ===')
    reg_payload = {'email': user['email'], 'password': user['password'], 'password_confirm': user['password'], 'full_name': user['name'], 'device_id': user['device_id']}
    post('/auth/register/', reg_payload)
    print('\n=== LOGIN ===')
    status, body = post('/auth/login/', {'email': user['email'], 'password': user['password'], 'device_id': user['device_id']})
    tokens = None
    if status in (200, 201) and body:
        try:
            parsed = json.loads(body)
            tokens = parsed.get('data') or parsed
        except Exception:
            tokens = None
    if tokens and 'access' in tokens:
        access = tokens['access']
        refresh = tokens.get('refresh')
        print('\n=== ME ===')
        # call /me with Authorization header
        url = base + '/auth/me/'
        req = urllib.request.Request(url, headers={'Authorization': f'Bearer {access}'})
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                print('ME STATUS', r.status)
                print(r.read().decode('utf-8'))
        except urllib.error.HTTPError as e:
            print('ME ERROR', e.code, e.read().decode('utf-8'))
        print('\n=== REFRESH ===')
        if refresh:
            status2, body2 = post('/auth/token/refresh/', {'refresh': refresh, 'device_id': user['device_id']})
            if status2 in (200, 201) and body2:
                try:
                    parsed2 = json.loads(body2)
                    print('REFRESH RESPONSE:', parsed2.get('data') or parsed2)
                except Exception:
                    print('REFRESH PARSE ERROR')
        print('\n=== LOGOUT ===')
        if refresh:
            # include Authorization header for logout
            post('/auth/logout/', {'refresh': refresh, 'device_id': user['device_id']}, headers={'Authorization': f'Bearer {access}'})
    else:
        print('No tokens obtained; login/register may have failed.')
