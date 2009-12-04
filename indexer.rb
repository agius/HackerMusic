require 'rubygems'
require 'sequel'
require 'sqlite3'
require 'tagfile/tagfile'

DATABASE = 'hacker_music.db'
BASE_DIR = '/Users/andrewevans/Music'

class HM_Indexer

  def scan(dir)
    Dir.entries(dir).each do |d|
      next if d == '.' or d == '..'
      path = dir + '/' + d
      if File.directory?(path)
        scan(path) 
      else
        next if not d =~ /\.mp3$/
        tag = TagFile::File.new(path)
        item = {:filename => path}
        item[:title] = tag.title or ''
        item[:artist] = tag.artist or ''
        item[:album] = tag.album or ''
        item[:year] = tag.year or ''
        item[:genre] = tag.genre or ''
        item[:track] = tag.track or ''
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
    @DB = Sequel.sqlite(database)
    @dataset = @DB[:songs]
  end
  
end

indexer = HM_Indexer.new(DATABASE)
indexer.scan(BASE_DIR)
puts 'Complete'