import base64
import io
import json
import unittest
import threading
from urllib.request import Request, urlopen
from unittest.mock import patch
from urllib.error import HTTPError
import photo_server as server

class PhotoServerTests(unittest.TestCase):
    def data(self):
        return {'title': 'Cook', 'description': 'Prepare a dish', 'evidence': 'Show the meal', 'image': base64.b64encode(b'\x89PNG\r\n\x1a\nfixture').decode()}

    def result(self, verdict='match', finish='STOP'):
        return {'candidates': [{'finishReason': finish, 'content': {'parts': [{'text': json.dumps({'verdict': verdict, 'reason': 'Prepared meal visible.'})}]}}]}

    def test_validation(self):
        server.validate_input(self.data())
        for data in [{}, {**self.data(), 'image': 'garbage'}, {**self.data(), 'title': 'x' * 2001}, {**self.data(), 'image': base64.b64encode(b'not image').decode()}]:
            with self.assertRaises(ValueError):
                server.validate_input(data)

    def test_assessment_fails_closed(self):
        for verdict in ('match', 'mismatch', 'unclear'):
            self.assertEqual(server.parse_result(self.result(verdict))['verdict'], verdict)
        for result in ({}, self.result(finish='SAFETY'), self.result('approve')):
            with self.assertRaises(ValueError):
                server.parse_result(result)

    def test_key_only_in_upstream_header_and_schema_required(self):
        response = io.BytesIO(json.dumps(self.result()).encode())
        with patch.object(server, 'urlopen', return_value=response) as call:
            self.assertEqual(server.review(self.data(), 'test-secret')['verdict'], 'match')
            request = call.call_args.args[0]
            self.assertEqual(request.get_header('X-goog-api-key'), 'test-secret')
            self.assertNotIn('test-secret', request.full_url)
            self.assertNotIn('test-secret', request.data.decode())
            payload = json.loads(request.data)
            self.assertEqual(payload['generationConfig']['responseJsonSchema']['required'], ['verdict', 'reason'])

class GatewayTests(unittest.TestCase):
    def setUp(self):
        self.http = server.ThreadingHTTPServer(('127.0.0.1', 0), server.Handler)
        self.worker = threading.Thread(target=self.http.serve_forever, daemon=True)
        self.worker.start()
        self.addCleanup(self.http.server_close)
        self.addCleanup(self.http.shutdown)
        server.REQUEST_TIMES.clear()

    def post(self, origin='http://localhost:8083', body=None):
        body = PhotoServerTests().data() if body is None else body
        request = Request(f'http://127.0.0.1:{self.http.server_port}/api/photo-review',
            data=json.dumps(body).encode(), headers={'Host': '127.0.0.1:8084', 'Origin': origin, 'Content-Type': 'application/json'})
        try:
            with urlopen(request, timeout=2) as response:
                return response.status, json.loads(response.read()), response.headers
        except HTTPError as error:
            with error:
                return error.code, json.loads(error.read()), error.headers

    def test_missing_key_invalid_origin_and_bad_input_do_not_call_google(self):
        with patch.object(server, 'api_key', return_value=''), patch.object(server, 'review') as review:
            self.assertEqual(self.post()[0], 503)
            self.assertEqual(self.post(origin='https://untrusted.example')[0], 403)
            self.assertEqual(self.post(body={})[0], 400)
            review.assert_not_called()

    def test_verdicts_and_quota_are_relayed_without_credentials(self):
        with patch.object(server, 'api_key', return_value='test-secret'):
            for verdict in ('match', 'mismatch', 'unclear'):
                with patch.object(server, 'review', return_value={'verdict': verdict, 'reason': 'Clear subject.'}):
                    code, body, headers = self.post()
                    self.assertEqual(code, 200)
                    self.assertEqual(body['verdict'], verdict)
                    self.assertEqual(headers['Access-Control-Allow-Origin'], 'http://localhost:8083')
                    self.assertNotIn('test-secret', json.dumps(body))
            with patch.object(server, 'review', side_effect=HTTPError('https://google', 429, 'secret diagnostics', {}, None)):
                code, body, _ = self.post()
                self.assertEqual(code, 429)
                self.assertNotIn('secret', json.dumps(body))

if __name__ == '__main__':
    unittest.main()
