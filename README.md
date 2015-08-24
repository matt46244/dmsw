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
Update current_week to the desired week you wish to run this against in dmsw.rb

Run after the game has been played.
./dmsw.rb

