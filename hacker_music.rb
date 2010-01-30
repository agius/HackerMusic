require 'rubygems'
require 'sinatra'
require 'sequel'
require 'digest/sha1'
require 'haml'
require 'shout'
require 'HM_Indexer'

$CONFIG = YAML.load_file('settings.yaml')
case $CONFIG[:database][:type]
when 'mysql'
  $DB = Sequel.connect($CONFIG[:database][:connect_string])
else
  $DB = Sequel.sqlite($CONFIG[:database][:file_name])
end
set :sessions, true

def filter_admin
  if not session[:id]
    session[:notice] = 'Log in, please'
    redirect '/'
  end
  @user = $DB[:users].filter(:id => session[:id]).first
  if not @user[:is_admin]
    session[:notice] = 'You don\'t have permission'
    redirect '/'
  end
end

def filter_user
  if not session[:id]
    session[:notice] = 'Log in, please'
    redirect '/'
  end
end

def filter_uploads
  if not $CONFIG[:settings][:allow_uploads]
    session[:notice] = 'Uploads are not allowed on this server.'
    redirect back 
  end
end

def filter_downloads
  if not $CONFIG[:settings][:allow_downloads]
    session[:notice] = 'Downloads are not allowed on this server.'
    redirect back 
  end
end

helpers do
  include Rack::Utils
  alias_method :url, :escape
end

before do
  @user = session[:id] if session[:id]
  @notice = session[:notice] if session[:notice] and !session[:notice].empty?
  @current_song = $DB[:plays].select(:song_id.as(:id), :title, :artist, :album, :genre, :year).join(:songs, :id => :song_id).order(:played_at.desc).first
  @upcoming = $DB[:votes].group(:song_id).join(:songs, :id => :song_id).select(:song_id, :title, :artist, :COUNT.sql_function(:song_id).as(:cnt)).order(:cnt.desc, :voted_at.asc)
  if @user
    @my_votes = $DB[:votes].select({:votes__id => :vote_id}, :song_id, :user_id, :title, :artist, :album, :genre, :year).filter(:user_id => @user).join(:songs, :id => :song_id).all
  end
  @tune_in_link = "http://#{self.env['SERVER_NAME']}:#{$CONFIG[:shout_station][:port]}/#{$CONFIG[:shout_station][:mount]}"
  @styles = ['reset.css', 'hm.css']
  @scripts = ['jquery-1.3.2.js']
  @scripts << 'audio-player.js' if $CONFIG[:settings][:allow_downloads]
  @scripts << 'hm.js'
  @title = $CONFIG[:settings][:title]
end

get '/search' do
  @q = params[:q]
  @songs = $DB[:songs].grep([:title, :artist, :filename, :genre, :album], ["%#{@q}%", {:case_insensitive => true}])
  haml :song_list, :layout => !request.xhr?
end

get '/vote/:id' do |id|
  filter_user
  @songs = $DB[:songs]
  @song = @songs[:id => params[:id]]
  
  @votes = $DB[:votes]
  @votecount = $DB[:votes].filter(:user_id => @user).join(:songs, :id => :song_id).all
  if @votecount.count >= $CONFIG[:settings][:max_votes].to_i
    session[:notice] = 'You have used all your votes. Please clear some, then vote again.'
    redirect back
  end
  check = $DB[:votes].filter(:song_id => params[:id], :user_id => @user).first
  if check
    session[:notice] = 'You have already voted for this song. Branch out!'
    redirect back
  end
  vote_id = @votes.insert(:song_id => @song[:id], :user_id => @user, :voted_at => Time.now) if @song
  @vote = @votes[:id => vote_id]
  session[:notice] = 'You voted for: ' + @song[:title] + ' by ' + @song[:artist]
  redirect back
end

get '/cancel/:id' do
  filter_user
  
  if(params[:id] == 'all')
    $DB[:votes].filter(:user_id => @user).delete
    session[:notice] = 'Your votes have been cleared!'
    redirect back
  end
  
  vote = $DB[:votes].filter(:id => params[:id]).first
  if not vote
    session[:notice] = 'Delete what?'
    redirect back
  end
  
  if(vote[:user_id] != @user)
    session[:notice] = 'You do not have permission'
    redirect back
  end
  
  $DB[:votes].filter(:id => params[:id]).delete
  song = $DB[:songs].filter(:id => vote[:song_id]).first
  session[:notice] = 'Your vote for ' + song[:title] + ' has been cleared.'
  redirect back
end

post '/login' do
  @people = $DB[:users].filter(:name => params[:login])
  @person = @people.first
  if @person.nil?
    session[:notice] = 'Wrong name / password.'
    redirect back
  end
  
  password_hash = Digest::SHA1.hexdigest(params[:password] + @person[:salt])
  
  if password_hash == @person[:password_hash]
    session[:id] ||= @person[:id]
    session[:notice] = 'Logged In!'
    session[:is_admin] = @person[:is_admin]
  else
    session[:notice] = 'Wrong name / password.'
  end
  
  redirect back
end

get '/logout' do
  session[:id] = nil
  redirect back
end

get '/change' do
  haml :change_password
end

post '/change' do
  filter_user
  @person = $DB[:users].filter(:id => @user)
  salt = Time.new.to_f.to_s
  password_hash = Digest::SHA1.hexdigest(params[:new_password] + salt)
  $DB[:users].filter(:id => @user).update(:password_hash => password_hash, :salt => salt)
  session[:notice] = 'Password changed!'
  redirect '/'
end

get '/admin' do
  filter_admin
  @users = $DB[:users]
  haml :admin
end

post '/admin/user/create' do
  filter_admin
  $DB[:users].insert(:name => params[:name], :salt => $CONFIG[:users][:default_salt], :password_hash => Digest::SHA1.hexdigest($CONFIG[:users][:default_pass] + $CONFIG[:users][:default_salt]))
  redirect back
end

get '/admin/user/:name/reset' do
  filter_admin
  $DB[:users].filter(:name => params[:name]).update(:salt => $CONFIG[:users][:default_salt], :password_hash => Digest::SHA1.hexdigest($CONFIG[:users][:default_pass] + $CONFIG[:users][:default_salt]))
  session[:notice] = 'Password reset for ' + params[:name]
  redirect back
end

get '/admin/user/:name/delete' do
  filter_admin
  $DB[:users].filter(:name => params[:name]).delete
  session[:notice] = params[:name] + ' deleted.'
  redirect back
end

get '/title' do
  haml :browse_by_title
end

get '/title/:letter' do
  @songs = $DB[:songs].grep([:title], ["#{params[:letter]}%", {:case_insensitive => true}])
  haml :browse_by_title
end

get '/artist/list' do
  haml :browse_by_artist
end

get '/artist/list/:letter' do
  # Required for category_list.haml
  @field = :artist
  @list = $DB[:songs].grep([:artist], ["#{params[:letter]}%", {:case_insensitive => true}]).group_by(:artist)
  haml :browse_by_artist
end

get '/artist/view/:artist' do
  @artist = params[:artist]
  @songs = $DB[:songs].grep([:artist], ["#{params[:artist]}", {:case_insensitive => true}])
  haml :browse_by_artist
end

get '/album/list' do
  haml :browse_by_album
end

get '/album/list/:letter' do
  @field = :album
  @list = $DB[:songs].grep([:album], ["#{params[:letter]}%", {:case_insensitive => true}]).group_by(:album)
  haml :browse_by_album
end

get '/album/view/:album' do
  @album = params[:album]
  @songs = $DB[:songs].grep([:album], ["#{params[:album]}", {:case_insensitive => true}])
  haml :browse_by_album
end

get '/genre' do
  @tags = $DB[:songs].select(:COUNT.sql_function(:id).as(:cnt), :genre).group_by(:genre)
  # Required for tag_cloud partial
  @max = @tags.order(:cnt.desc).first[:cnt].to_i
  @min = @tags.order(:cnt.asc).first[:cnt].to_i
  @base_url = '/genre'
  @field = :genre
  @count = :cnt
  haml :browse_by_genre
end

get %r{/genre/(.*)} do |g|
  @genre = unescape g
  @songs = $DB[:songs].grep([:genre], ["#{@genre}%", {:case_insensitive => true}])
  haml :browse_by_genre
end

get '/year' do
  @tags = $DB[:songs].select(:COUNT.sql_function(:id).as(:cnt), :year).group_by(:year)
  # required for tag_cloud partial
  @max = @tags.order(:cnt.desc).first[:cnt].to_i
  @min = @tags.order(:cnt.asc).first[:cnt].to_i
  @base_url = '/year'
  @field = :year
  @count = :cnt
  haml :browse_by_year
end

get %r{/year/(.*)} do |y|
  @year = unescape y
  @songs = $DB[:songs].grep([:year], ["#{@year}%", {:case_insensitive => true}])
  haml :browse_by_year
end

get '/random' do |y|
  @songs = $DB[:songs].order(($CONFIG[:database][:type] == 'mysql' ? :RAND : :RANDOM).sql_function()).limit(10)
  haml :browse_by_random
end

get '/upcoming' do
  @songs = $DB[:votes].group(:song_id).join(:songs, :id => :song_id).select(:filename, :song_id.as(:id), :title, :artist, :COUNT.sql_function(:song_id).as(:cnt)).order(:cnt.desc, :voted_at.asc)
  haml :browse_by_upcoming
end

get '/get/:id' do
  filter_downloads
  @song = $DB[:songs].filter(:id => params[:id]).first
  return if not @song
  mime :mp3, 'audio/mpeg'
  send_file @song[:filename]
end

get '/upload' do
  filter_user
  filter_uploads
  @scripts << 'swfobject.js' << 'jquery.uploadify.v2.1.0.min.js' << 'hm_upload.js'
  @styles << 'uploadify.css'
  haml :upload_form
end

post '/upload' do
  if(params[:user_id])
    @user = params[:user_id]
  else
    filter_user
  end
  filter_uploads
  
  @user = $DB[:users].filter(:id => @user).first
  uploads_dir = $CONFIG[:database][:music_dir] + '/uploads/' + @user[:name] + '/'
  FileUtils.mkdir_p(uploads_dir)
  
  dest = uploads_dir + params[:Filename]
  if FileUtils.mv(params[:Filedata][:tempfile].path, dest)
    FileUtils.chmod 0755, dest
    indexer = HM_Indexer.new($DB)
    indexer.index(dest)
    session[:notice] = 'File uploaded: ' + params[:Filename]
  else
    return 'false' if params[:user_id]
    session[:notice] = 'File failed to upload.'
  end
  
  return 'true' if params[:user_id]
  redirect back
end

get '/' do
  @songs = $DB[:plays].join(:songs, :id => :song_id).group(:song_id).order(:played_at.desc).limit(10)
  haml :index
end
