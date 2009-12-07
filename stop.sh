#!/bin/bash
killall icecast
thin -C config.yml -R rackup_hm.ru stop
killall ruby streamer.rb