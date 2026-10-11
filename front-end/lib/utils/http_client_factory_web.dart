import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';

// On web we must enable credentials so the browser sends/stores cookies
// (e.g. the session cookie) on cross-origin requests.
http.Client createHttpClient() => BrowserClient()..withCredentials = true;
