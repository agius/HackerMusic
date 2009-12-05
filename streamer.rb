#!/usr/bin/ruby

# Stream all the files given on the commandline to the Icecast server on
# localhost. 

require 'rubygems'
require 'shout'
require 'sequel'

@config = YAML.load_file('config.yaml')
@station = @config[:shout_station]
@db = @config[:database]

DB = Sequel.sqlite(@db[:file_name])
BLOCKSIZE = 16384

s = Shout.new
s.host        = @station[:host]
s.port        = @station[:port]
s.mount       = @station[:mount]
s.user        = @station[:user]
s.pass        = @station[:pass]
s.name        = @station[:name]
s.description = @station[:description]
s.genre       = @station[:genre]
s.format      = Shout::MP3
s.connect

loop do
  songs = DB[:votes].select(:song_id, :filename, :title, :artist, :genre, :album, :year, :COUNT.sql_function(:song_id)).join(:songs, :id => :song_id).group(:song_id).order(:COUNT.sql_function(:song_id).desc, :voted_at.asc)
  songs = DB[:songs].order(:RANDOM.sql_function()) if songs.empty?
  song = songs.first
  
  votes = DB[:votes]
  votes.filter(:song_id => song[:song_id]).delete if not votes.empty?
  
  plays = DB[:plays]
  plays.insert(:song_id => song[:id], :played_at => Time.now)
  
  puts "sending data from #{song[:filename]}"
  m = ShoutMetadata.new
  m.add 'filename', song[:filename]
  m.add 'title', song[:title]
  m.add 'artist', song[:artist]
  m.add 'genre', song[:genre]
  m.add 'album', song[:album]
  m.add 'year', song[:year]
  s.metadata = m
  
  filename = song[:filename]
  File.open(filename) do |file|
    while data = file.read(BLOCKSIZE)
      s.send data
      s.sync
    end
  end
end

s.disconnect
