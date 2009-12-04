#!/usr/bin/ruby

# Stream all the files given on the commandline to the Icecast server on
# localhost. 

require 'rubygems'
require 'shout'
require 'sequel'

BLOCKSIZE = 16384

s = Shout.new
s.host = "localhost"
s.port = 8000
s.mount = "/hackermusic.mp3"
s.user = "source"
s.pass = "hackme"
s.format = Shout::MP3

s.connect

DB = Sequel.sqlite('hacker_music.db')

loop do
  songs = DB[:votes].select(:song_id, :filename, :COUNT.sql_function(:song_id)).join(:songs, :id => :song_id).group(:song_id).order(:COUNT.sql_function(:song_id).desc)
  songs = DB[:songs].order(:RAND.sql_function()) if not songs
  song = songs.first
  puts song
  @songs = DB[:votes]
  @songs.filter(:song_id => song[:song_id]).delete
  
  filename = song[:filename]
	File.open(filename) do |file|
		puts "sending data from #{filename}"
		m = ShoutMetadata.new
		m.add 'filename', filename
		s.metadata = m

		while data = file.read(BLOCKSIZE)
			s.send data
			s.sync
		end
	end
end

s.disconnect
