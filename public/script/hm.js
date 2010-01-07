$(document).ready(function(){
  AudioPlayer.setup("/flash/player.swf", {  
    width: 290
  });
  // search label
  var search_selector = '#q';
  var search_text = "Search by keyword...";
  if ($(search_selector).val() == "") $(search_selector).val(search_text);
  $(search_selector).focus(function()
    {
      if ($(this).val() == search_text) {
        $(this).val('');
      }
    }).blur(function()
    {
      if ($(this).val() == '') {
        $(this).val(search_text);
      }
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
