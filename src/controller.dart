import 'dart:io';
import 'dart:convert';
import 'dart:math';

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
  Point anchor = new Point(0, 0);

  Player(int gId, String lab, WebSocket sock) {
    gameId = gId;
    label = lab;
    socket = sock;
  }

  void drawField(Map<Point, String> labels) {
    for (int i = 0; i < 15; i++) {
      for (int j = 0; j < 15; j++) {
        var mes = {
          'x': i,
          'y': j,
          'label': labels[new Point(i + anchor.x, j + anchor.y)] ?? 'empty'
        };
        send(socket, 'redraw', mes);
      }
    }
  }
}
class Game {
  int id;
  Player o;
  Player x;
  Map<Point, String> labels = new Map<Point, String>();
  Game(int gid, Player px, Player po) {
    id = gid;
    x = px;
    o = po;
    x.drawField(labels);
    o.drawField(labels);
    x.isCurrent = true;
  }
  void act(Player player, var value) {
    if (player.isCurrent) {
      Point cell = new Point(value['x'] + player.anchor.x, value['y'] + player.anchor.y);
      if (labels[cell] != null) {
        return;
      }
      labels[cell] = player.label;

      send(x.socket, 'redraw', {
        'x': cell.x - x.anchor.x,
        'y': cell.y - x.anchor.y,
        'label': player.label
      });
      send(o.socket, 'redraw', {
        'x': cell.x - o.anchor.x,
        'y': cell.y - o.anchor.y,
        'label': player.label
      });
      player.isCurrent = false;

      var win = checkWin(player, cell);
      if (win == null) {
        if (player.label == 'x') {
          o.isCurrent = true;
        } else {
          x.isCurrent = true;
        }
      } else {
        var winX = {
        'x_0': win['x_0'] -x.anchor.x,
        'y_0': win['y_0'] - x.anchor.y,
        'x_1': win['x_1'] - x.anchor.x,
        'y_1': win['y_1'] - x.anchor.y
      };
        var winO = {
          'x_0': win['x_0'] - o.anchor.x,
          'y_0': win['y_0'] - o.anchor.y,
          'x_1': win['x_1'] - o.anchor.x,
          'y_1': win['y_1'] - o.anchor.y
        };
        send(x.socket, 'win', winX);
        send(o.socket, 'win', winO);
      }
    }
  }
  dynamic checkWin(Player player, Point fresh) {
    var win = null;
    String label = player.label;
    win = (((checkDirection(fresh, new Point(0, 1), label) ??
             checkDirection(fresh, new Point(1, 0), label)) ??
             checkDirection(fresh, new Point(1, 1), label)) ??
             checkDirection(fresh, new Point(-1, 1), label));
    return win;
  }
  dynamic checkDirection(Point pivot, Point direction, String label) {
    while (labels[pivot] == label) {
      pivot -= direction;
    }
    int line = 0;
    pivot += direction;
    var win = {
      'x_0': pivot.x,
      'x_1': null,
      'y_0': pivot.y,
      'y_1': null
    };
    while (labels[pivot] == label && line < 5) {
      pivot += direction;
      line += 1;
    }
    pivot -= direction;
    if (line == 5) {
      win['x_1'] = pivot.x;
      win['y_1'] = pivot.y;
      return win;
    } else {
      return null;
    }
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
    } else if (mes['type'] == 'redraw request') {
      if (mes['value'] == 'up') {
        player.anchor = new Point(player.anchor.x, player.anchor.y - 1);
      } else if (mes['value'] == 'down') {
        player.anchor = new Point(player.anchor.x, player.anchor.y + 1);
      } else if (mes['value'] == 'left') {
        player.anchor = new Point(player.anchor.x - 1, player.anchor.y);
      } else if (mes['value'] == 'right') {
        player.anchor = new Point(player.anchor.x + 1, player.anchor.y);
      }
      player.drawField(game.labels);
    }
  }
}
