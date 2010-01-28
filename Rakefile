require 'rubygems'
require 'rake'

$CONFIG = YAML.load_file('config.yml')
$SETTING = YAML.load_file('settings.yaml')

task :default => :test

desc "Run all tests."
task :test do
  #TODO: connect to test runner
end

desc "Index music directory."
task :index do
  music_dir = $SETTING[:database][:music_dir]
  puts "== Index music files in #{music_dir}."
  sh "ruby indexer.rb"
end

desc "Start the webinterface."
task :wi_start do
  puts "== Try to start the webinterface."
  begin
    sh "thin -C config.yml -R rackup_hm.ru start"
    puts "== HackerMusic webinterface starting on http://localhost:4567"
  rescue
    puts "== There was an error, maybe the server is already running?"
  end
end

desc "Stop the webinterface."
task :wi_stop do
  puts "== Try to kill the thin server process."
  # TODO: read thin pid from thin.pid file
  sh "pkill thin"
end

desc "Start icecast server."
task :icecast_start do
  puts "== Start icecast server."
  sh "icecast2 -b -c icecast.xml"
end

desc "Stop the icecast server."
task :icecast_stop do
  puts "== Stop the icecast server."
  sh "pkill icecast"
end

desc "Start streamer."
task :streamer_start do
  puts "== Start streamer."
  sh "ruby streamer.rb >/tmp/streamer.log &"
end

desc "Stop streamer."
task :streamer_stop do
  puts "== Stop streamer."
  sh "pkill streamer.rb"
end
