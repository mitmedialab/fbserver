canvas = Raphael("background", "100%", "100%");

var rad = Math.PI / 180
function sector(paper, cx, cy, r, startAngle, endAngle, params) {
		var x1 = cx + r * Math.cos(-startAngle * rad),
				x2 = cx + r * Math.cos(-endAngle * rad),
				y1 = cy + r * Math.sin(-startAngle * rad),
				y2 = cy + r * Math.sin(-endAngle * rad);
		return paper.path(["M", cx, cy, "L", x1, y1, "A", r, r, 0, +(endAngle - startAngle > 180), 0, x2, y2, "z"]).attr(params);
}


function drawpie(){
	cx = window.innerWidth/2.0
	cy = window.innerHeight/2.0 + 120;

	circle = canvas.circle(cx, cx, 10);
	circle.attr("fill", "#f00");

	sector(canvas, cx, cy, 900, -10, 75, {fill: "rgb(211,113,136)", "stroke-width": 0});
	sector(canvas, cx, cy, 900, 74, 191, {fill: "rgb(105,127,158)", "stroke-width": 0});
	sector(canvas, cx, cy, 900, 190, 351, {fill: "rgb(91,91,91)", "stroke-width": 0});
}

drawpie();

$(window).resize(function() {
  drawpie();
});
