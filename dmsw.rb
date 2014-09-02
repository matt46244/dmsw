#!/usr/bin/env ruby

#automatically check the newest score from espn and update both the twitter account and webpage for didmichiganstatewin.com

require 'twitter'
require 'nokogiri'
require 'httparty'
require 'net/ftp'

require_relative "config"

#did we find the config file
raise "You need to create a file called config.rb. See config.rb.example." if !defined? $config_found
puts "Loaded config okay."

#setup twitter client
client = Twitter::REST::Client.new do |config|
  config.consumer_key = $consumer_key
  config.consumer_secret = $consumer_secret
  config.access_token = $access_token
  config.access_token_secret = $access_token_secret
end

#get webpage from espn for parsing
response = HTTParty.get('http://m.espn.go.com/ncf/teamschedule?teamId=127&wjb=')
if response.code == 200
  doc = Nokogiri::HTML(response.body)
  puts "Got page okay."
else
  raise ArgumentError, error_message(url, path)
end

#what week are we currently in?
target_week = 1

current_week = 0
win_lose = ""
msu_score = 0
other_score = 0
url_num = ""

#loop through available fields
doc.css('tr').each do |row|
  row.css('td.ind').each do |column|
    column.css('a').each do |game|
      if game.content.start_with?('W ', 'L ') #found a game!
	current_week = current_week + 1
	#split the field into the parts we need
        temp = game.content.split(' ')
        win_lose = temp.first
	temp2 = temp.last.split('-')
        if win_lose == "W"
	  msu_score=temp2.first.to_i
	  other_score=temp2.last.to_i
        else
          other_score=temp2.first_to_i
          msu_score=temp2.last.to_i
        end
        #find the game number to build the URL from later
        temp = game.to_s
        url_num = temp.match('gameId=(.*)&')[1]
      end
     #debug info
     puts game
    end
  end
end

#debug info
puts current_week
puts win_lose
puts msu_score
puts other_score
puts url_num

#if we didn't get scores for the correct week, abort
if !(target_week == current_week)
  raise "No new scores - nothing to do. Aborting."
end

# ok, we got a valid score - let's continue

# generate webpage from templates

File.delete("./index.html")

file = File.open("template.1", 'rb')
html = file.read.chomp
file.close
file = File.open('template.2', 'rb')
if win_lose == "W"
  html.concat("<p class=\"yes\">Yes.")
else
  html.concat("<p class=\"no\>No.")
end
html.concat(file.read.chomp)
file.close
html.concat(url_num)
html.concat("\" target=\"_blank\">")
if win_lose == "W"
  html.concat(msu_score.to_s)
  html.concat("-")
  html.concat(other_score.to_s)
else
  html.concat(other_score.to_s)
  html.concat("-")
  html.concat(msu_score.to_s)
end
file = File.open('template.3', 'rb')
html.concat(file.read.chomp)
file.close

index = File.open('index.html', 'w')
index.write(html)
index.close

#upload template to ftp
ftp = Net::FTP.new('didmichiganstatewin.com')
ftp.login(user=$ftp_user, passwd = $ftp_password)
ftp.putbinaryfile('index.html')
ftp.close

# generate the tweet for posting
if win_lose == "W"
tweet = "YES. "
tweet.concat(msu_score.to_s)
tweet.concat("-")
tweet.concat(other_score.to_s)
else
tweet = "NO. "
tweet.concat(other_score.to_s)
tweet.concat("-")
tweet.concat(msu_score.to_s)
end
tweet.concat(". didmichiganstatewin.com")

# write tweet to twitter
puts tweet
#client.update(tweet)

