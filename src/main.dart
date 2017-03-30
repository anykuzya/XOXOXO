import 'dart:io';
import 'dart:async';
import 'controller.dart';

void main(List<String> args) {
  // var - auto
  // non-blocking call of HttpServer.bind
  Future<HttpServer> server = HttpServer.bind(InternetAddress.ANY_IP_V6, 8000);
  Controller controller = new Controller();
  server.then((HttpServer server) {
    server.listen((HttpRequest request) {
      Uri uri = request.uri;
      if (uri.toString()=="/") {
        uri = Uri.parse("/index.html");
      }
      if (!uri.toString().startsWith("/ws")) {
        // Platform.script -- current script file name
        Uri publicDir = Platform.script.resolve("../web/");
        Uri fileUri = publicDir.resolve("." + uri.toString());
        print(fileUri.toString());
        File fileToRead = new File(fileUri.toFilePath());
        // File......Sync - blocking operation
        if (fileToRead.existsSync()) {
          var stream = fileToRead.openRead();
          if (uri.toString().endsWith('.html')) {
            request.response.headers.add("Content-type", "text/html");
          } else if (uri.toString().endsWith('.js')) {
            request.response.headers.add("Content-type", "text/javascript");
          }
          stream.pipe(request.response);
        }
        else {
          request.response.statusCode = 404;
          request.response.close();
        }
      }
      else {
        WebSocketTransformer.upgrade(request).then((WebSocket socket) {
          controller.handleClient(socket);
        });
      }
    });
  });
}
