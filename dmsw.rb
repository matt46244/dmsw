#!/usr/bin/env ruby

#automatically check the newest score from espn and update both the twitter account and webpage for didmichiganstatewin.com

require 'twitter'
require 'nokogiri'
require 'httparty'
require 'net/ftp'

require_relative "config"

#did we find the config file?
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

# ok, we got a valid score - let's continue

# generate webpage from templates
file = File.open("template.1", 'rb')
html = file.read.chomp
file.close

file = File.open('template.2', 'rb')
win_lose == "W" ? html.concat("<p class=\"yes\">Yes.") : html.concat("<p class=\"no\">No.")
html.concat(file.read.chomp)
file.close

html.concat(url_num + "\" target=\"_blank\">" + score)

file = File.open('template.3', 'rb')
html.concat(file.read.chomp)
file.close

#ok, delete the old file and write the new file
File.delete("./index.html")
index = File.open('index.html', 'w')
index.write(html)
index.close

#upload template to ftp
ftp = Net::FTP.new('didmichiganstatewin.com')
ftp.login(user=$ftp_user, passwd = $ftp_password)
ftp.putbinaryfile('index.html')
ftp.close

# generate the tweet for posting
tweet = win_lose == "W" ? "YES. " + score : "NO. " + score

tweet.concat(". didmichiganstatewin.com")

# write tweet to twitter
puts tweet
#client.update(tweet)

