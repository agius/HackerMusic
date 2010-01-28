require 'rubygems'
require 'rake'

$CONFIG = YAML.load_file('settings.yaml')

task :default => :test

desc "Run all tests."
task :test do
  #TODO: connect to test runner
  sh "no test files ..."
end

desc "Index music directory."
task :index do
  music_dir = $CONFIG[:database][:music_dir]
  puts "Index music files in #{music_dir}."
  sh "ruby indexer.rb"
end
