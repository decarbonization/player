var activePoint = null;

$(document).ready(function () {
	var points = $('.point');
	points.each(function (index, element) {
		var point = $(element);
		point.mouseup(function () {
			$('#gallery #images').cycle(index, 'fade');
		});
	});
	
	$('#gallery #images').cycle({ 
        fx: 'fade',
        speed: 500,
        timeout: 4000,
		before: function(currSlideElement, nextSlideElement, options, forwardFlag) {
			if(activePoint)
				activePoint.removeClass('selected');
			
			var pointName = $(nextSlideElement).attr("rb-slide-name");
			activePoint = $("#" + pointName);
			activePoint.addClass('selected');
		},
    });
});

function switchSection(newActiveButton, newSection)
{
    $("#content .visible")
    .removeClass("visible")
    .addClass("hidden");
    
    $("#content " + newSection)
    .removeClass("hidden")
    .addClass("visible");
    
    $(".nav-link.selected").removeClass("selected").addClass("unselected");
    $(newActiveButton).addClass("selected").removeClass("unselected");
}