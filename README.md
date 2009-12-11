Hacker Music
============
Hacker Music is a stupidly simple web application designed to solve a bedeviling problem: what music should we be playing in the office right now? We wanted to use Apple's super-slick Itunes DJ / iTouch Remote combo, but not everyone in the office has an iTouch-ready device. We looked at [Tunez](http://tunez.sourceforge.net/ "Tunez MP3 Jukebox") which is an icecast interface with a voting system, but that looked like more bells and whistles than we needed.

Hacker Music is an interface to an [Icecast](http://www.icecast.org/ "Icecast streaming music") server. Once you've set up the database and populated it with songs, you run a non-terminating Ruby script that continually sends songs to your Icecast server, and Hacker Music provides a small webapp where people can vote on what should be played next. We've included the default icecast.xml file, which works with the default configuration settings in HM, so once you've got all the prerequisites installed you should be good to go.

The rules are simple: 

*   Each user gets a fixed number of votes, which they can apply towards songs. 
*   You cannot vote for a song twice. 
*   The song with the most votes gets played next. 
*   If songs are tied for votes, whichever song got the first vote chronologically goes first. 
*   If nobody's voted for anything recently, it plays a random song from the database.

Setup
------------
We set up Hacker Music on a mac laptop, so there will be a lot of references to "port" - the [MacPorts](http://www.macports.org/ "MacPorts") package management system. If you don't have it installed, go ahead and do so now. If you're on Linux, this stuff should work just the same - use your favorite package manager instead ([yum](http://yum.baseurl.org/ "YUM Package Manager"), for example).

1.  Update Ruby and RubyGems:
    We found our mac (running Leopard) had a waaay out-of-date version of Ruby and its package management system, Gems. There were some issues which prevented us from upgrading, so we had to do a fresh install. Not hard, just run:
    
    > sudo port install ruby
    
    > sudo port install rb-rubygems
    
    > sudo gem update --system
    
    And you should be all upgraded.
    
2.  Install dependancies:
    Some of the gems used by Hacker Music depend on some cool libraries and UNIX tools. Here's how to install them:
    
    > sudo port install libshout2
    
    > sudo port install libffi
    
    > sudo port install icecast2
    
    > sudo port install sqlite3
    
    > sudo port install taglib
    
    Feel free to skip any libraries you already have installed
    
3.  Set up Gemcutter
    If you don't use [Gemcutter](http://gemcutter.org/ "Gemcutter") as your default repository for Ruby Gems, you probably should. It's kind of a big deal. Here's how to do that, from their site:
    > gem install gemcutter
    
    > gem tumble
    
    Boom! You're done. Gemcutter is now your default place to look for gems.
    
4.  Install Required Gems:
    Hacker Music uses a number of truly awesome tools the Ruby community has crafted. Here's the command list:
    
    > gem install sqlite3-ruby
    
    > gem install sinatra-sinatra
    
    > gem install sequel
    
    > gem install haml
    
    > gem install ruby-shout
    
    > gem install thin
    
5.  Once you're done installing all those dependancies (painless, right?), you're almost ready to rock! You will want to move the following files and update them to point to your application directory:
    
    > config.yml-dist -> config.yml
    
    > settings.yaml-dist -> settings.yaml
    
    > icecast.xml-dist -> icecast.xml
    
6.  Run the following from your Hacker Music directory:
    
    > ruby setup.rb
    
    That sets up your database and all the associated tables / default entries from settings.yaml
    
    > ruby indexer.rb
    
    That should recursively index all the MP3's from the music directory specified in settings.yaml
    
    > icecast2 -b -c icecast.xml
    > thin -c config.yml -R rackup_hm.ru start
    > ruby streamer.rb >logs/streamer.log &
    
    This defaults to starting an icecast server in the background using icecast.xml in the application directory, and starting the Sinatra application using [Thin](http://code.macournoyer.com/thin/ "Thin Ruby Server"), and running streamer.rb in the background.
    
7.  Start rockin'! Go to [http://localhost:4567](http://localhost:4567 "Your Sinatra Server"), log in with the default admin name / password specified in settings.yaml and run your server.

Settings
-----------
The included settings.yaml contains a number of settings related to the operation of Hacker Music. Here's a little explanation:

> :shout_station

All these properties relate to the icecast server you want Hacker Music to control. If you haven't used icecast before, leave these alone and run icecast with the included icecast.xml file for configuration.

> :database

These settings relate to the default database, which uses SQLite. We may put in more advanced database stuff at some point, in which case these options will grow more robust.

> :database -> :music_dir

The default directory which indexer.rb scans for MP3 files (no other formats are currently supported). Specify a hard path from the filesystem base for best results.

> :settings

Contains application-level settings that affect the logic of Hacker Music. Currently, you can customize the maximum number of votes each user has. Note that they can only vote once per song.

> :users

A list of default user names, with a default password and salt provided. We put in the names of people in our office - that way there's no messy account-creation crap, and the office can get to using the application right away. 

> :users -> :admin

A name from the above list to be appointed admin. There should only be one admin, whose only real power is controlling who has accounts on Hacker Music and resetting passwords. More admins is just overkill.