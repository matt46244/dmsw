#!/usr/bin/env ruby

#automatically check the newest score from espn and update both the twitter account and webpage for didmichiganstatewin.com

require 'twitter'
require 'nokogiri'
require 'httparty'
require 'net/ftp'

require_relative "config"
require_relative "helper"

#did we find the config file? error out if we didn't, it's kind of important
raise "You need to create a file called config.rb. See config.rb.example." if !defined? $config_found
puts "Loaded config okay."

#get webpage from espn for parsing
response = HTTParty.get('http://m.espn.go.com/ncf/teamschedule?teamId=127&wjb=')
if response.code == 200
  doc = Nokogiri::HTML(response.body)
  puts "Got page okay."
else
  raise ArgumentError, error_message(url, path)
end

#what week are we currently in? we only want to get the scores from the current week
target_week = 1

#setup some variables
current_week = 0
win_lose = ""
score = ""
url_num = ""

#loop through available fields that we found on the website
doc.css('tr').each do |row|
  row.css('td.ind').each do |column|
    column.css('a').each do |game|
      if game.content.start_with?('W ', 'L ') #found a game!
	current_week = current_week + 1
	#split the field into the parts we need
        temp = game.content.split(' ')
        win_lose = temp.first
	score = temp.last

       #find the espn game number to build the URL from later
        temp = game.to_s
        url_num = temp.match('gameId=(.*)&')[1]
      end
     #debug output
     puts game
    end
  end
end

#debug output
puts current_week
puts win_lose
puts score
puts url_num

#if we didn't get scores for the correct week, abort
raise "No new scores - nothing to do. Aborting." unless target_week == current_week

# ok, we got a valid score - let's continue and generate the new page
html = generate_html(win_lose, score, url_num)

#delete the old file and write the new file, but only if it's different from the last time we ran this
if html == load_old_index
  puts "Files match - no need to update."
else
  delete_index_file
  write_index_file(html)
  upload_index_to_ftp
end

# generate the tweet for posting
tweet = generate_tweet(win_lose, score)

#check to see if we're tweeting the same thing, otherwise, update!
if tweet == load_old_tweet
  puts "Tweets match - no need to update."
else
  tweet_new_tweet(tweet)
end

