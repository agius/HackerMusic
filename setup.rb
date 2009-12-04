require 'rubygems'
require 'sequel'
require 'digest/sha1'

# Create DB / table
DB = Sequel.sqlite('hacker_music.db')
DB.run 'DROP TABLE IF EXISTS songs'

DB.create_table :songs do
  primary_key :id
  String :filename, :unique => true, :null => false
  String :title
  String :artist
  String :album
  String :genre
  String :year
  String :track
  Float :length
end

DB.run 'DROP TABLE IF EXISTS votes'

DB.create_table :votes do
  primary_key :id
  foreign_key :song_id, :songs
  foreign_key :user_id, :users
end

DB.run 'DROP TABLE IF EXISTS users'

DB.create_table :users do
  primary_key :id
  String :name
  String :password_hash
  String :salt
end

DB[:users].insert(:name => 'andrew', :salt => 'default', :password_hash => Digest::SHA1.hexdigest('noodledefault'))
DB[:users].insert(:name => 'ben', :salt => 'default', :password_hash => Digest::SHA1.hexdigest('noodledefault'))
DB[:users].insert(:name => 'mike', :salt => 'default', :password_hash => Digest::SHA1.hexdigest('noodledefault'))
DB[:users].insert(:name => 'torsten', :salt => 'default', :password_hash => Digest::SHA1.hexdigest('noodledefault'))
DB[:users].insert(:name => 'chas', :salt => 'default', :password_hash => Digest::SHA1.hexdigest('noodledefault'))