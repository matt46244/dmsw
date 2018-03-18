# encoding: utf-8

require 'twitter'
require 'nokogiri'
require 'httparty'
require 'net/ftp'
require 'logger'
require 'koala'
require 'date'

require_relative "config"

#lets define some stuff

class Game
  attr_accessor :win_lose, :score, :url_num, :current_week, :sport

  def initialize(win_lose, score, url_num, current_week, sport)
    @win_lose = win_lose
    @score = score
    @url_num = url_num
    @current_week = current_week
    @sport = sport
  end

  #loop through available fields that we found on the website and parse it into usuable data
  def parse_games(doc)
    doc.css('tr').each do |row|
      row.css('td.ind').each do |column|
        column.css('a').each do |game|
          if game.content.start_with?('W', 'L') #found a game!
            @current_week = @current_week + 1
            #split the field into the parts we need
            temp = game.content
            @win_lose = game.content.chars.first
            @score = temp.split(@win_lose).last
            
            #find the espn game number to build the URL for later
            temp = game.to_s
            @url_num = temp.match('gameId=(.*)&')[1]
            $log.debug("Found week #{ @current_week } score info.")
          end

          #debug output
          $log.debug(game.content)
        end
      end
    end

    #debug output
    $log.debug(@current_week)
    $log.debug(@win_lose)
    $log.debug(@score)
    $log.debug(@url_num)
  end
  
  #if we didn't get scores for the correct week, abort
  def check_week(target_week)
    $log.info("Looking for week #{ target_week } scores, using week #{ @current_week } scores.")
    $log.info("No new scores - nothing to do. Aborting.") unless target_week == @current_week
    raise "No new scores - nothing to do. Aborting." unless target_week == @current_week 
  end

end

#get the html page from espn so that we can parse it
def get_from_espn(game)
  $log.info("Initializing...")
  
  url = game.sport == "bb" ? "http://m.espn.go.com/ncb/teamschedule?month=" + Date.today.month.to_s + "&season=" + Date.today.year.to_s + "&teamId=127&wjb=" : "http://m.espn.go.com/ncf/teamschedule?teamId=127&wjb="
  
  $log.debug(game.sport)
  $log.debug(url)

  response = HTTParty.get(url)

  if response.code == 200
    doc = Nokogiri::HTML(response.body)
    $log.debug("Got page from ESPN okay.")
  else
    raise ArgumentError, error_message(url, path)
  end

  return doc
end

#delete the old index file before we create the new one
def delete_index_file
  $log.info("Deleting old index.html file...")
  File.delete("/home/pi/programming/ruby/dmsw/index.html")
end

#generate new html file from the template
def generate_html(game)
  file = File.open("/home/pi/programming/ruby/dmsw/template.1", 'rb')
  html = file.read.chomp
  file.close
 
  if game.sport == "fb"
    file = File.open('/home/pi/programming/ruby/dmsw/template.2', 'rb')
  end
  if game.sport == "bb"
    file = File.open('/home/pi/programming/ruby/dmsw/template_bb.2', 'rb')
  end
  
  game.win_lose == "W" ? html.concat("<p class=\"yes\">Yes.") : html.concat("<p class=\"no\">No.")
  html.concat(file.read.chomp)
  file.close

  html.concat(game.url_num + "\" target=\"_blank\">" + game.score.lstrip)

  file = File.open('/home/pi/programming/ruby/dmsw/template.3', 'rb')
  html.concat(file.read.chomp)
  file.close
  return html
end

#write the new index file that's ready for uploading
def write_index_file(html, sport)
  index = File.open('/home/pi/programming/ruby/dmsw/index.html', 'w')
  index.write(html)
  index.close
  $log.info("Successfully created new index.html.")

  if sport == "fb"
  index = File.open('/home/pi/programming/ruby/dmsw/index.fb', 'w')
  index.write(html)
  index.close
  $log.info("Successfully created new index.fb.")
  end

  if sport == "bb"
  index = File.open('/home/pi/programming/ruby/dmsw/index.bb', 'w')
  index.write(html)
  index.close
  $log.info("Successfully created new index.bb.")
  end

end

#upload the new index to the ftp
def upload_index_to_ftp
  ftp = Net::FTP.new('didmsuwin.com')
  ftp.login(user=$ftp_user, passwd = $ftp_password)
  ftp.putbinaryfile('/home/pi/programming/ruby/dmsw/index.html')
  ftp.close
  $log.info("Uploaded to FTP okay!")
end

#load old index file as a string
def load_old_index(sport)
  if sport == "fb"
    file = File.open('/home/pi/programming/ruby/dmsw/index.fb', 'rb')
    end
  if sport == "bb"
    file = File.open('/home/pi/programming/ruby/dmsw/index.bb', 'rb')
  end
  html = file.read.chomp
  file.close
  return html
end

#load sport
def read_sport
  file = File.open('/home/pi/programming/ruby/dmsw/sport.config', 'rb')
  sport = file.read.chomp
  $log.debug("Info from sport.config:")
  $log.debug(sport)
  file.close
  return sport
end

#load week info as a number
def read_week
  file = File.open('/home/pi/programming/ruby/dmsw/week.config', 'rb')
  week = file.read.chomp.to_i
  $log.debug("Info from week.config:")
  $log.debug(week)
  file.close
  return week
end

#increment week into the file
def increment_week(current_week)
  File.truncate('/home/pi/programming/ruby/dmsw/week.config', 0)
  file = File.open('/home/pi/programming/ruby/dmsw/week.config', 'w')
  next_week = current_week + 1
  file.write(next_week)
  $log.debug("next week:")
  $log.debug(next_week)
  file.close
  $log.info("Incrementing week.")
end

#generate the new tweet
def generate_tweet(game)
  tweet = game.sport == "bb" ? "🏀 " : "🏈 "

  game.win_lose == "W" ? tweet.concat("YES. " + game.score) : tweet.concat("NO. " + game.score)

  tweet.concat(". didmsuwin.com")
  
  $log.debug(tweet)

  return tweet

end

#find the latest tweet we've posted
def load_old_tweet
  #setup twitter client
  client = Twitter::REST::Client.new do |config|
    config.consumer_key = $consumer_key
    config.consumer_secret = $consumer_secret
    config.access_token = $access_token
    config.access_token_secret = $access_token_secret
  end

  #replace t.co link with didmichiganstatewin.com/didmsuwin.com so the comparison will work
  return client.user_timeline("didmsuwin").first.text.split('http').first + "didmsuwin.com"
end

#send the tweet to twitter
def tweet_new_tweet(tweet)
  #setup twitter client
  client = Twitter::REST::Client.new do |config|
    config.consumer_key = $consumer_key
    config.consumer_secret = $consumer_secret
    config.access_token = $access_token
    config.access_token_secret = $access_token_secret
  end

  $log.debug(tweet)
  client.update(tweet)
  $log.info("Successfully tweeted!")
end

def load_old_post
  #setup fb client
  @page = Koala::Facebook::API.new($fb_access_token)
  post = @page.get_connections("me", "feed")
  
  $log.debug(post)

  if post != []
    return post.first['message']
  else
    return ""
  end
end

def post_new_post(tweet)
  $log.debug(tweet)

  #setup fb client
  @page = Koala::Facebook::API.new($fb_access_token)
  @page.put_connections("me", "feed", :message => tweet)

  $log.info("Succesfully posted to Facebook!")
end

