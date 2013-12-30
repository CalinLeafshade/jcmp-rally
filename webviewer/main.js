
var colors = [ '#ff0000', '#00ff00', '#0000ff', '#ffff00', '#00ffff', '#ff00ff' ];

function convertCoords(x,y)
{
	return { x: x * 2048 / 32768, y: y * 2048 / 32768 };
}

function addEvent(x,y,ev)
{
	if (ev.type == "enterVehicle")
	{
		$('<div></div>').appendTo('body').addClass("eventSpot").data("text","Entered vehicle " + ev.vehicle).css({left:  x - 10,top:   y - 10});
	}
	else if (ev.type == "leftVehicle") {
		$('<div></div>').appendTo('body').addClass("eventSpot").data("text","Left Vehicle").css({left:  x - 10,top:   y - 10});
	}
}

$(document).ready(function(){

	$(document).on("mouseenter", ".eventSpot", function(event) {
		var pos = $(this).position();
		$('#eventDescription').css({left: pos.left + 30, top: pos.top}).html($(this).data("text"));
	})
	
	$(document).on("mouseleave", ".eventSpot", function(event) {
		$('#eventDescription').css({left: -500, top: -500});
	})

	var canvas = document.getElementById("mainCanvas");
	var ctx = canvas.getContext("2d");
	var colorID = 0;
	var legendText = "";
	for(var name in Data) {
		var d = Data[name];
		ctx.beginPath();
		ctx.strokeStyle=colors[colorID];
		ctx.lineWidth=5;
		var last = false;
		for (i in d) 
		{
			var tick = d[i];
			var x = tick.position[0];
			var y = tick.position[1];
			var c = convertCoords(x,y);
			if (i == 0) {
				ctx.moveTo(c.x,c.y);
			}
			else {
				ctx.lineTo(c.x,c.y);
				
			}
			if (tick.type == "enterVehicle") 
			{
				addEvent(c.x,c.y,tick)
			}
			else if (tick.type == "leftVehicle")
			{
				addEvent(c.x,c.y,tick)
			}
		}
		ctx.stroke();
		legendText += "<span style='color: " + colors[colorID] + ";'>" + name + "</span></br>";
		colorID = colorID + 1;
	}	
	
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
