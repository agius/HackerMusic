$(window).load(function(){
  $('#q').val('Search by keyword...')
  $('#q').bind('focus', function(){
    if($('#q').val() == 'Search by keyword...') $('#q').val('')
  });
  $('#q').bind('blur', function(){
    if($('#q').val() == '') $('#q').val('Search by keyword...')
  });
  /*
  $('#search').submit(function(e){
    $('#main').load('/search', $('#search').serialize());
    return false;
  });
  */
  
});