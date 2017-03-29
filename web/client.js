/**
 * Created by anna on 28.03.17.
 */


var field = document.getElementById("field");
ctx = field.getContext('2d');
size = field.width / 15;
// var connection = new WebSocket("ws://" +
//     window.location.hostname + ":" + window.location.port +
//     "/ws"
// );
function drawSquare(x, y, label) {
    var field = document.getElementById("field");
    ctx.fillStyle = '#FFFFFF';
    ctx.fillRect(x * size, y * size, size, size);
    ctx.strokeRect(x * size, y * size, size, size);
    if (label == 'empty') {
    } else if (label == 'x') {
        ctx.beginPath();
        ctx.moveTo(x*size + size / 6, y*size + size / 6);
        ctx.lineTo(x*size + size * 5 / 6, y*size + size * 5 /6);

        ctx.moveTo(x*size + size / 6, y*size + size * 5 / 6);
        ctx.lineTo(x*size + size * 5 / 6, y*size + size /6);
        ctx.stroke();
    }  else if (label == 'o') {
        ctx.beginPath();
        ctx.arc(x * size + size/2, y * size + size / 2, size / 3, 0, 2 * Math.PI);
        ctx.stroke();
    }
}
function drawWin(x_0, y_0, x_1, y_1) {
    ctx.strokeStyle = 'red';
    ctx.beginPath();
    ctx.moveTo(x_0 * size + size / 2, y_0 * size + size / 2);
    ctx.lineTo(x_1 * size + size / 2, y_1 * size + size / 2);
    ctx.stroke();
}
function sendMess(mes) {
    // connection.send(JSON.stringify(mes));
}

// connection.onmessage = function (event) {
//     var mes = JSON.parse(event.data);
//     drawSquare(mes.value.x, mes.value.y, mes.value.label);
// };

field.onclick = function (event) {
    var mes = {
        'type': 'action',
        'value': {x: Math.floor(event.offsetX / size), y: Math.floor(event.offsetY / size)}
    }
    sendMess(mes);
}
document.onkeydown = function (event) {
    var mes = {
        'type': 'redraw request',
        'value': undefined
    }
    if (event.keyCode == 37) {
        mes.value = 'left';
    } else  if (event.keyCode == 38) {
        mes.value = 'up';
    } else  if (event.keyCode == 39) {
        mes.value = 'right';
    } else if (event.keyCode == 40) {
        mes.value = 'down'
    }

}