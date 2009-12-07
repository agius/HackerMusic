#!/bin/bash
icecast -b -c icecast.xml
thin -C config.yml -R rackup_hm.ru start
ruby streamer.rb >logs/streamer.log &