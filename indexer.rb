require 'rubygems'
require 'sequel'
require 'HM_Indexer'

$CONFIG = YAML.load_file('settings.yaml')
@music_dir = $CONFIG[:database][:music_dir]

case $CONFIG[:database][:type]
when 'mysql'
  DB = Sequel.connect($CONFIG[:database][:connect_string])
else
  DB = Sequel.sqlite($CONFIG[:database][:file_name])
end
indexer = HM_Indexer.new(DB)
indexer.scan(@music_dir)
puts 'Complete'