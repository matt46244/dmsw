#lets define some stuff

#delete the old index file before we create the new one
def delete_index_file
  puts "Deleting old index.html file..."
  File.delete("./index.html")
end

#generate new html file from the template
def generate_html(win_lose, score, url_num)
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
  return html
end

#write the new index file that's ready for uploading
def write_index_file(html)
  index = File.open('index.html', 'w')
  index.write(html)
  index.close
  puts "Successfully created new index.html."
end

#upload the new index to the ftp
def upload_index_to_ftp
  ftp = Net::FTP.new('didmichiganstatewin.com')
  ftp.login(user=$ftp_user, passwd = $ftp_password)
  ftp.putbinaryfile('index.html')
  ftp.close
  puts "Uploaded to FTP okay!"
end

#load old index file as a string
def load_old_index
  file = File.open('index.html', 'rb')
  html = file.read.chomp
  file.close
  return html
end

#generate the new tweet
def generate_tweet(win_lose, score)
  tweet = win_lose == "W" ? "YES. " + score : "NO. " + score

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

def tweet_new_tweet(tweet)
  #setup twitter client
  client = Twitter::REST::Client.new do |config|
    config.consumer_key = $consumer_key
    config.consumer_secret = $consumer_secret
    config.access_token = $access_token
    config.access_token_secret = $access_token_secret
  end

  puts tweet
  #client.update(tweet)
  puts "Successfully tweeted!"
end

def parse_games
#parse games here
end
