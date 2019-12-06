dmsw
========
A small program to update a website and post to twitter after the result of a game.

Install
========
Rename config.rb.example to config.rb and fill in the necessary information.

Here's what I did on my new raspberry pi:\

install new rvm/ruby:
curl -L https://get.rvm.io | bash -s stable --ruby

restart terminal

install bundler:
gem install bundler
bundle install
gem install koala

make sure helper and config are in the folder


Usage
========
Os of December 2019, this currently runs from the command line and no longer uses the hardcoded weeks or sport configs.

Run after the game has been played.
./dmsw.rb SPORT WEEK
SPORT is either fb for football or bb for basketball.

EXAMPLE: ./dmsw.rb fb 12
EXAMPLE: ./dmsw.rb bb 4

Here's a sample crontab line:
*/5 * * * Sat /home/pi/.rvm/rubies/ruby-2.2.1/bin/ruby /home/pi/programming/ruby/dmsw/dmsw.rb fb 12 > /tmp/fb_log.txt

