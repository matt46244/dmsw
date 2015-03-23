require 'twitter'
require 'nokogiri'
require 'httparty'
require 'net/ftp'
require 'logger'

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
            @win_lose = temp.scan(/[LW]/)[0]
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
    raise "No new scores - nothing to do. Aborting." unless target_week == @current_week 
  end

end

#get the html page from espn so that we can parse it
def get_from_espn(game)
  $log.info("Initializing...")
  
  url = game.sport == "bb" ? "http://m.espn.go.com/ncb/teamschedule?teamId=127&wjb=" : "http://m.espn.go.com/ncf/teamschedule?teamId=127&wjb="
  
  $log.info(game.sport)
  $log.info(url)

  response = HTTParty.get(url)

  if response.code == 200
    doc = Nokogiri::HTML(response.body)
    $log.info("Got page from ESPN okay.")
  else
    raise ArgumentError, error_message(url, path)
  end

  return doc
end

#delete the old index file before we create the new one
def delete_index_file
  $log.info("Deleting old index.html file...")
  File.delete("/home/matt/Documents/programming/ruby/dmsw/index.html")
end

#generate new html file from the template
def generate_html(game)
  file = File.open("/home/matt/Documents/programming/ruby/dmsw/template.1", 'rb')
  html = file.read.chomp
  file.close
 
  if game.sport == "fb"
    file = File.open('/home/matt/Documents/programming/ruby/dmsw/template.2', 'rb')
  end
  if game.sport == "bb"
    file = File.open('/home/matt/Documents/programming/ruby/dmsw/template_bb.2', 'rb')
  end
  
  game.win_lose == "W" ? html.concat("<p class=\"yes\">Yes.") : html.concat("<p class=\"no\">No.")
  html.concat(file.read.chomp)
  file.close

  html.concat(game.url_num + "\" target=\"_blank\">" + game.score.lstrip)

  file = File.open('/home/matt/Documents/programming/ruby/dmsw/template.3', 'rb')
  html.concat(file.read.chomp)
  file.close
  return html
end

#write the new index file that's ready for uploading
def write_index_file(html)
  index = File.open('/home/matt/Documents/programming/ruby/dmsw/index.html', 'w')
  index.write(html)
  index.close
  $log.info("Successfully created new index.html.")
end

#upload the new index to the ftp
def upload_index_to_ftp
  ftp = Net::FTP.new('didmichiganstatewin.com')
  ftp.login(user=$ftp_user, passwd = $ftp_password)
  ftp.putbinaryfile('/home/matt/Documents/programming/ruby/dmsw/index.html')
  ftp.close
  $log.info("Uploaded to FTP okay!")
end

#load old index file as a string
def load_old_index
  file = File.open('/home/matt/Documents/programming/ruby/dmsw/index.html', 'rb')
  html = file.read.chomp
  file.close
  return html
end

#generate the new tweet
def generate_tweet(game)
  tweet = game.win_lose == "W" ? "YES. " + game.score : "NO. " + game.score

  tweet.concat(". didmichiganstatewin.com")
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

  #replace t.co link with didmichiganstatewin.com so the comparison will work
  return client.user_timeline("didmsuwin").first.text.split('http').first + "didmichiganstatewin.com"
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
