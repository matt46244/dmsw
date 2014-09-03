#!/usr/bin/env ruby

#automatically check the newest score from espn and update both the twitter account and webpage for didmichiganstatewin.com

require 'twitter'
require 'nokogiri'
require 'httparty'
require 'net/ftp'

require_relative "config"
require_relative "helper"

#get webpage from espn for parsing
doc = get_from_espn

#what week are we currently in? we only want to get the scores from the current week
target_week = 1

game = Game.new("", "", "", 0)
game.parse_games(doc)

#if we didn't get scores for the correct week, abort
raise "No new scores - nothing to do. Aborting." unless target_week == game.current_week

# ok, we got a valid score - let's continue and generate the new page
html = generate_html(game.win_lose, game.score, game.url_num)

#delete the old file and write the new file, but only if it's different from the last time we ran this
if html == load_old_index
  puts "Files match - no need to update."
else
  delete_index_file
  write_index_file(html)
  upload_index_to_ftp
end

# generate the tweet for posting
tweet = generate_tweet(game.win_lose, game.score)

#check to see if we're tweeting the same thing, otherwise, update!
if tweet == load_old_tweet
  puts "Tweets match - no need to update."
else
  tweet_new_tweet(tweet)
end

