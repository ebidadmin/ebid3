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
	
	$('select#username').bind('change', function() { window.location.pathname = $(this).val() });
	$('select#status').bind('change', function() { window.location.pathname = ($(this).val()) });
	$('select#seller').bind('change', function() { window.location.pathname = $(this).val() });
	
});

// jQuery.ajaxSetup({ 
//   'beforeSend': function(xhr) {xhr.setRequestHeader("Accept", "text/javascript")}
// })
// 
// jQuery.fn.submitWithAjax = function() {
//   this.submit(function() {
//     $.post(this.action, $(this).serialize(), null, "script");
//     return false;
//   })
//   return this;
// };
// 
// $(document).ready(function() {
//   $("#new_review").submitWithAjax();
// })