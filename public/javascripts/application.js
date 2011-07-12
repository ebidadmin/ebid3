// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

$(function() {
	$("#parts .pagination a").live("click", function() {
    $(".pagination").html("Page is loading...");
		$.getScript(this.href);
		return false;
	});

	$("#search-form input").keyup(function() {
		$.get($("#search-form").attr("action"), $("#search-form").serialize(), null, "script");
		return false;
	});
	
	$('select#username, select#brand, select#status, select#seller, select#buyer').bind('change', function() { window.location.pathname = $(this).val() });
	
	$("#entry_final_submit").bind("click", function() {
	    $(".spinner").toggle() ;
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
});

// function remove_fields(link) {
//   $(link).prev("input[type=hidden]").val("1");
//   $(link).closest(".fields").hide();
// }
// 
// function add_fields(link, association, content) {
//   var new_id = new Date().getTime();
//   var regexp = new RegExp("new_" + association, "g")
//   $(link).parent().before(content.replace(regexp, new_id));
// }
