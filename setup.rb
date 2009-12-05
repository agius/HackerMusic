require 'rubygems'
require 'sequel'
require 'digest/sha1'

@config = YAML.load_file('config.yaml')
@db = @config[:database]
@users = @config[:users]

# Create DB / table
DB = Sequel.sqlite(@db[:file_name])
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
  Time :voted_at
end

DB.run 'DROP TABLE IF EXISTS users'

DB.create_table :users do
  primary_key :id
  String :name
  String :password_hash
  String :salt
end

@users[:names].each do |name|
  DB[:users].insert(:name => name, :salt => @users[:default_salt], :password_hash => Digest::SHA1.hexdigest(@users[:default_pass] + @users[:default_salt]))
end

DB.run 'DROP TABLE IF EXISTS plays'

DB.create_table :plays do
  primary_key :id
  foreign_key :song_id
  Time :played_at
end