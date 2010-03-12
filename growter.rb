#!/usr/bin/ruby
require 'rubygems'
require 'json'
require 'eventmachine'
require 'em/buftok'
require 'meow'

require 'twitter_stream'

AUTH = 'USER:PASSWORD'
SEARCH = 'sxsw'

meow = Meow.new('Growter', 'Note', Meow.import_image('twitter.png'))

EventMachine::run {
  stream = TwitterStream.connect(
      :content => "track=#{SEARCH}",
      :auth => AUTH
  )
    
  stream.each_item do |msg|
    tweet = JSON.load(msg)
    
    meow.notify "#{tweet['user']['name']} (#{tweet['user']['screen_name']})", tweet['text'] do
      system "open http://twitter.com/#{tweet['user']['screen_name']}/statuses/#{tweet['id']}"
    end
  end
  
  stream.on_error do |message|
    $stdout.print "error: #{message}\n"
    $stdout.flush
  end
  
  stream.on_reconnect do |timeout, retries|
    $stdout.print "reconnecting in: #{timeout} seconds\n"
    $stdout.flush
  end
  
  stream.on_max_reconnects do |timeout, retries|
    $stdout.print "Failed after #{retries} failed reconnects\n"
    $stdout.flush
  end
  
  trap('TERM') {  
    stream.stop
    EventMachine.stop if EventMachine.reactor_running? 
  }
}
puts "The event loop has ended"