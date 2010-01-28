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
  puts "Index music files in #{music_dir}."
  sh "ruby indexer.rb"
end

desc "Starting the webinterface."
task :wi_start do
  puts "Try to start the webinterface."
  begin
    sh "thin -C config.yml -R rackup_hm.ru start"
  rescue
    puts "There was an error, maybe the server is already running?"
  end
end

desc "Stop the webinterface"
task :wi_stop do
  puts "Try to kill the thin server process."
  sh "pkill thin"
end
