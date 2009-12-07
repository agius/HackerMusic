require 'rubygems'
require 'sequel'
require 'sqlite3'
require 'tagfile/tagfile'

$CONFIG = YAML.load_file('settings.yaml')
@music_dir = $CONFIG[:database][:music_dir]

class HM_Indexer

  def scan(dir)
    Dir.entries(dir).each do |d|
      next if d == '.' or d == '..'
      path = dir + '/' + d
      if File.directory?(path)
        scan(path) 
      else
        next if not d =~ /\.mp3$/
        next if @dataset.filter(:filename => path).first
        tag = TagFile::File.new(path)
        matches = /([^\/]+)\/([^\/]+)\/([^\.\/]+)\.mp3$/.match(path)
        album = matches ? matches[1] : ''
        artist = matches ? matches[2] : ''
        title = matches ? matches[3] : ''
        item = {:filename => path}
        item[:title] = tag.title == '' ? title : tag.title
        item[:artist] = tag.artist == '' ? artist : tag.artist
        item[:album] = tag.album == '' ? album : tag.album
        item[:year] = tag.year or 'None'
        item[:genre] = tag.genre or 'None'
        item[:track] = tag.track or '0'
        begin
          @dataset.insert(item)
        rescue
          puts 'Skipped: '
          puts item.inspect
          puts $!.message
        end
      end
    end
  end
  
  def initialize(database)
    @DB = database
    @dataset = @DB[:songs]
  end
  
end

case $CONFIG[:database][:type]
when 'mysql'
  DB = Sequel.connect($CONFIG[:database][:connect_string])
else
  DB = Sequel.sqlite($CONFIG[:database][:file_name])
end
indexer = HM_Indexer.new(DB)
indexer.scan(@music_dir)
puts 'Complete'