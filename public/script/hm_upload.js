$(document).ready(function(){
    var data = {
        'user_id' : $('#user_id').val()
    };
    $('#fileInput').uploadify({
        'uploader'  : '/flash/uploadify.swf',
        'script'    : '/upload',
        'cancelImg' : '/image/cancel.png',
        'auto'      : false,
        'folder'    : '/uploads',
        'multi'     : true,
        'fileDesc'  : 'MP3 Music Files',
        'fileExt'   : '*.mp3;*.mpeg;',
        'sizeLimit' : 10485760, //10MB
        'scriptData': data
    });
    $('#upload_files').click(function(e){
        $('#fileInput').uploadifyUpload();
        return false;
    });
    $('#clear_queue').click(function(e){
        $('#fileInput').uploadifyClearQueue();
        return false;
    });
});