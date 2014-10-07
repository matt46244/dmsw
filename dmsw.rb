#!/usr/bin/env ruby
require_relative "helper"

#automatically check the newest score from espn and update both the twitter account and webpage for didmichiganstatewin.com

#setup logging
#DEBUG<INFO<WARN<Error<FATAL<UNKNOWN
$log = Logger.new(STDOUT)
$log.level = Logger::INFO

#what week are we currently in? we only want to get the scores from the current week
target_week = 6

#get webpage from espn for parsing
game = Game.new("", "", "", 0)
game.parse_games(get_from_espn)

#if we didn't get scores for the correct week, abort
game.check_week(target_week)

# ok, we got a valid score - let's continue and generate the new page
html = generate_html(game)

#delete the old file and write the new file, but only if it's different from the last time we ran this
if html == load_old_index
  $log.info( "Files match - no need to update.")
else
  delete_index_file
  write_index_file(html)
  upload_index_to_ftp
end

# generate the tweet for posting
tweet = generate_tweet(game)

#check to see if we're tweeting the same thing, otherwise, update!
if tweet == load_old_tweet
  $log.info("Tweets match - no need to update.")
else
  tweet_new_tweet(tweet)
end

