$(function() {
	$("#parts-pagination a").live("click", function() {
    $(".pagination").html("Page is loading...");
		$.getScript(this.href);
		return false;
	});

	// $("#search-form input").keyup(function() {
	// 	alert("Change observed! new value: " + this.value );
	// 	return false;
	// });
	
	$("select#username, select#brand, select#status, select#seller, select#buyer").bind("change", function() { window.location.pathname = $(this).val() });
	
	$("#entry_submit, #entry_final_submit, #finalize-button, #message_submit, #cancel-order .red-button, #order_submit, #bid-form .green-button").live("click", function() {
	    $(".spinner").toggle();
	});
	
	$("label.inlined + input.input-text").each(function (type) {

		$(this).focus(function () {
			$(this).prev("label.inlined").addClass("focus");
		});

		$(this).keypress(function () {
			$(this).prev("label.inlined").addClass("has-text").removeClass("focus");
		});

		$(this).blur(function () {
			if($(this).val() == "") {
				$(this).prev("label.inlined").removeClass("has-text").removeClass("focus");
			}
		});
	});	// $("#jMenu").jMenu();
	
	$("#select-all").bind("click",function() { 
		$("form").find("input:checkbox").attr("checked", true);
		return false;
	});
	
	$(document).ajaxSend(function(e, xhr, options) {
	  var token = $("meta[name='csrf-token']").attr("content");
	  xhr.setRequestHeader("X-CSRF-Token", token);
	});
	
	$('a.delete-fee').bind('ajax:success', function() {  
		var id = $(this).attr('id');
		var parent = 'div#' + id;
		$(parent).fadeOut();
	});
	
	// $('.photo').error(function () { 
	// 	$(this).attr('src=images/rails.png')
	// });
	
});

