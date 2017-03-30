import 'dart:io';
import 'dart:convert';

void send(WebSocket sock, type, mes) {
  sock.add(JSON.encode(
      {"type": type, "value": mes}
  ));
}

class Player {
  int gameId;
  String label;
  bool isCurrent = false;
  WebSocket socket;
  Player(int gId, String lab, WebSocket sock) {
    gameId = gId;
    label = lab;
    socket = sock;
  }
}
class Cell {
  int x;
  int y;
  Cell(x, y) {
    this.x = x;
    this.y = y;
  }
}
class Game {
  int id;
  String cur;
  Player o;
  Player x;
  Map<Cell, String> labels = new Map<Cell, String>();
  Cell anchor = new Cell(0,0);
  Game(int gid, Player px, Player po) {
    id = gid;
    x = px;
    o = po;
    drawField(x.socket);
    drawField(o.socket);
  }
  void drawField(WebSocket sock) {
    for (int i = 0; i < 15; i++) {
      for (int j = 0; j < 15; j++) {
        int x = anchor.x + i;
        int y = anchor.y + i;
        var mes = {'x': x, 'y': y, 'label': labels[new Cell(x, y)] ?? 'empty'};
        mes['x'] = anchor.x + i;
        mes['y'] = anchor.y + j;
        mes['label'] = labels[new Cell(mes['x'], mes['y'])] ?? 'empty';
        send(sock, 'redraw', mes);
      }
    }
  }
  void act(Player player, var value) {
    Cell cell = new Cell(value['x'], value['y']);
    labels[cell] = player.label;
    send(x.socket, 'redraw', {'x': cell.x, 'y':cell.y, 'label': player.label});
    send(o.socket, 'redraw', {'x': cell.x, 'y':cell.y, 'label': player.label});
  }

}
class Controller {
  Map<WebSocket, Player> allClients = new Map<WebSocket, Player>();
  List<Game> games = new List<Game>();
  WebSocket waiting = null;
  void handleClient(WebSocket socket){
    send(socket, "wait", "");
    if (waiting == null) {
      waiting = socket;
    } else {
      int id = games.length;
      Player x = new Player(id, 'x', waiting);
      Player o = new Player(id, 'o', socket);
      allClients[waiting] = x;
      waiting.listen((data) {
        receive(x.socket, data);
      });
      allClients[socket] = o;
      socket.listen((data){
        receive(o.socket, data);
      });
      games.add(new Game(id, x, o));
      waiting = null;
    }
  }

  void receive(WebSocket socket, var data) {
    Player player = allClients[socket];
    Game game = games[player.gameId];
    var mes = JSON.decode(data);
    if (mes['type'] == 'action') {
      game.act(player, mes['value']);
    }
  }
}
