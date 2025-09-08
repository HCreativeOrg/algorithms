var canvas = document.getElementById("myCanvas");
var ctx = canvas.getContext("2d");

function drawCanvas() {
    test(ctx);
    requestAnimationFrame(drawCanvas);
}

function test(ctx) {

}