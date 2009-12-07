require 'rubygems'
require 'sequel'
require 'digest/sha1'

$CONFIG = YAML.load_file('settings.yaml')
$users = $CONFIG[:users]
$users[:default_hash] = Digest::SHA1.hexdigest($users[:default_pass] + $users[:default_salt])

# Create DB / table
case $CONFIG[:database][:type]
when 'mysql'
  DB = Sequel.connect($CONFIG[:database][:connect_string])
  DB.run 'SET foreign_key_checks = 0'
else
  DB = Sequel.sqlite($CONFIG[:database][:file_name])
end

# Create songs table
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

# Create users table
DB.run 'DROP TABLE IF EXISTS users'

DB.create_table :users do
  primary_key :id
  String :name
  String :password_hash, :default => $users[:default_hash]
  String :salt, :default => $users[:default_salt]
  boolean :is_admin, :default => false
end

# Set up default users list
$users[:names].each do |name|
  DB[:users].insert(:name => name, :salt => $users[:default_salt], :password_hash => $users[:default_hash])
end

# Set up default admin
DB[:users].filter(:name => $users[:admin]).update(:is_admin => true)

# Create votes table
DB.run 'DROP TABLE IF EXISTS votes'

DB.create_table :votes do
  primary_key :id
  foreign_key :song_id, :table => :songs, :key => :id
  foreign_key :user_id, :table => :users, :key => :id
  Time :voted_at
end

# Create archives table
DB.run 'DROP TABLE IF EXISTS votes_archives'

DB.create_table :votes_archives do
  primary_key :id
  foreign_key :song_id, :table => :songs, :key => :id
  foreign_key :user_id, :table => :users, :key => :id
  Time :voted_at
end

# Create plays table
DB.run 'DROP TABLE IF EXISTS plays'

DB.create_table :plays do
  primary_key :id
  foreign_key :song_id, :table => :songs, :key => :id
  Time :played_at
end

if $CONFIG[:database][:type] == 'mysql'
  DB.run 'SET foreign_key_checks = 1'
end

puts 'Tables created.'