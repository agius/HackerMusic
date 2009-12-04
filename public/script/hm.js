$(window).load(function(){
	$('#search').submit(function(e){
		$('#songs').load('/search', $('#search').serialize());
		return false;
	});
});