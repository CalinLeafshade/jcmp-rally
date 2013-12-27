
var colors = [ '#ff0000', '#00ff00', '#0000ff', '#ffff00', '#00ffff', '#ff00ff' ];

function convertCoords(x,y)
{
	return { x: x * 2048 / 32768, y: y * 2048 / 32768 };
}

$(document).ready(function(){

	var canvas = document.getElementById("mainCanvas");
	var ctx = canvas.getContext("2d");
	var colorID = 0;
	var legendText = "";
	for(var name in Data) {
		var d = Data[name];
		ctx.strokeStyle=colors[colorID];
		ctx.lineWidth=5;
		var last = false;
		for (i in d) 
		{
			var tick = d[i];
			console.log(tick);
			var x = tick.position[0];
			var y = tick.position[1];
			var c = convertCoords(x,y);
			if (i == 0) {
				ctx.moveTo(c.x,c.y);
			}
			else {
				console.log("lol");
				ctx.lineTo(c.x,c.y);
			}
		}
		legendText += "<span style='color: " + colors[colorID] + ";'>" + name + "</span></br>";
		colorID = colorID + 1;
	}	
	ctx.stroke();
	$('#legend').html(legendText);
	
});

$(document).on('mousemove', function(e){
    $('#coords').css({
       left:  e.pageX + 20,
       top:   e.pageY + 20
    });
    var x = e.pageX / (2048 / 32768);
    var y = e.pageY / (2048 / 32768);
	$('#coords').html(x + ", " + y);
});
