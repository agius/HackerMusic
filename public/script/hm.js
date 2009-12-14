$(document).ready(function(){
  AudioPlayer.setup("/flash/player.swf", {  
    width: 290
  });
  $('#q').val('Search by keyword...')
  $('#q').bind('focus', function(){
    if($('#q').val() == 'Search by keyword...') $('#q').val('')
  });
  $('#q').bind('blur', function(){
    if($('#q').val() == '') $('#q').val('Search by keyword...')
  });
  $('.player_link').each(function(i){
    $(this).bind('click', function(e){
        href = e.target.href
        id = href.substring(href.indexOf('#') + 1)
        AudioPlayer.embed(id + '_player', {soundFile: "/get/" + id, autostart: 'yes'});
        return false;
    });
  });
});