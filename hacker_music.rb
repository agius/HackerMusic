require 'rubygems'
require 'sinatra'
require 'sequel'
require 'digest/sha1'
require 'haml'
require 'shout'

$CONFIG = YAML.load_file('config.yaml')
$DB = Sequel.sqlite($CONFIG[:database][:file_name])
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

helpers do
  include Rack::Utils
  alias_method :url, :escape
end

before do
  @user = session[:id] if session[:id]
  @notice = session[:notice]
  @current_song = $DB[:plays].join(:songs, :id => :song_id).order(:played_at.desc).first
  @upcoming = $DB[:votes].group(:song_id).join(:songs, :id => :song_id).select(:title, :artist, :COUNT.sql_function(:song_id).as(:cnt)).order(:cnt.desc, :voted_at.asc)
end

get '/search' do
  @songs = $DB[:songs].grep([:title, :artist, :filename, :genre, :album], "%#{params[:q]}%")
  haml :song_list, :layout => !request.xhr?
end

get '/vote/:id' do |id|
  if not @user
    session[:notice] = 'You must be logged in to vote!'
    redirect back
  end
  @songs = $DB[:songs]
  @song = @songs[:id => params[:id]]
  
  @votes = $DB[:votes]
  @yourvote = $DB[:votes].filter(:user_id => @user).join(:songs, :id => :song_id).first
  if @yourvote
    session[:notice] = 'You already voted for: ' + @yourvote[:title] + ' by ' + @yourvote[:artist] + ' | <a href="/cancel">Clear My Vote</a>'
    redirect back
  end
  vote_id = @votes.insert(:song_id => @song[:id], :user_id => @user, :voted_at => Time.now) if not @song.nil? and not @yourvote
  @vote = @votes[:id => vote_id]
  session[:notice] = 'You voted for: ' + @song[:title] + ' by ' + @song[:artist]
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
  @person = $DB[:users].filter(:id => @user)
  salt = Time.new.to_f.to_s
  password_hash = Digest::SHA1.hexdigest(params[:new_password] + salt)
  $DB[:users].update(:password_hash => password_hash, :salt => salt)
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

get '/admin/user/:name/:action' do
  filter_admin
  case params[:action]
  when 'reset'
    $DB[:users].filter(:name => params[:name]).update(:salt => $CONFIG[:users][:default_salt], :password_hash => Digest::SHA1.hexdigest($CONFIG[:users][:default_pass] + $CONFIG[:users][:default_salt]))
    session[:notice] = 'Password reset for ' + params[:name]
  when 'delete'
    $DB[:users].filter(:name => params[:name]).delete
    session[:notice] = params[:name] + ' deleted.'
  end
  redirect back
end

get '/cancel' do
  $DB[:votes].filter(:user_id => @user).delete
  session[:notice] = 'Your votes have been cleared.'
  redirect back
end

get '/title' do
  haml :browse_by_title
end

get '/title/:letter' do
  @songs = $DB[:songs].grep([:title], "#{params[:letter]}%")
  haml :browse_by_title
end

get '/artist' do
  haml :browse_by_artist
end

get '/artist/:letter' do
  @songs = $DB[:songs].grep([:artist], "#{params[:letter]}%")
  haml :browse_by_artist
end

get '/album' do
  haml :browse_by_album
end

get '/album/:letter' do
  @songs = $DB[:songs].grep([:album], "#{params[:letter]}%")
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
  genre = unescape g
  @songs = $DB[:songs].grep([:genre], "#{g}%")
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
  genre = unescape y
  @songs = $DB[:songs].grep([:year], "#{y}%")
  haml :browse_by_year
end

get '/' do
  @songs = $DB[:plays].join(:songs, :id => :song_id).group(:song_id).order(:played_at.desc).limit(10)
  haml :index
end