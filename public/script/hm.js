$(window).load(function(){
	$('#search').submit(function(e){
		$('#main').load('/search', $('#search').serialize());
		return false;
	});
});