require 'rubygems'
require 'sinatra'
require 'sequel'
require 'digest/sha1'
require 'haml'

$DB = Sequel.sqlite('hacker_music.db')
set :sessions, true

before do
  @user = session[:id] if session[:id]
  @notice = session[:notice]
end

get '/search' do
  @songs = $DB[:songs].grep([:title, :artist, :filename, :genre, :album], "%#{params[:q]}%")
  #session[:notice] = @songs.sql
  haml :search, :layout => !request.xhr?
end

get '/vote/:id' do |id|
  @songs = $DB[:songs]
  @song = @songs[:id => params[:id]]
  
  @votes = $DB[:votes]
  @yourvote = $DB[:votes].filter(:user_id => @user).join(:songs, :id => :song_id).first
  if @yourvote
    session[:notice] = 'You already voted for: ' + @yourvote[:title] + ' by ' + @yourvote[:artist] + '<a href="/cancel">Cancel</a>'
    redirect '/'
  end
  vote_id = @votes.insert(:song_id => @song[:id], :user_id => @user) if not @song.nil? and not @yourvote
  @vote = @votes[:id => vote_id]
  session[:notice] = 'You voted for: ' + @song[:title] + ' by ' + @song[:artist]
  redirect '/'
end

post '/login' do
  @people = $DB[:users].filter(:name => params[:login])
  @person = @people.first
  if @person.nil?
    session[:notice] = 'Wrong name / password.'
    redirect '/'
  end
  
  password_hash = Digest::SHA1.hexdigest(params[:password] + @person[:salt])
  
  if password_hash == @person[:password_hash]
    session[:id] ||= @person[:id]
    session[:notice] = 'Logged In!'
  else
    session[:notice] = 'Wrong name / password.'
  end
  
  redirect '/'
end

get '/logout' do
  session[:id] = nil
  redirect '/'
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

get '/cancel' do
  $DB[:votes].filter(:user_id => @user).delete
  session[:notice] = 'Your votes have been cleared.'
  redirect '/'
end

get '/' do
  @songs = $DB[:songs]
  @votes = $DB[:votes].group(:song_id).join(:songs, :id => :song_id).select(:title, :artist, :COUNT.sql_function(:song_id).as(:cnt)).order(:cnt.desc)
  haml :index
end