#!/usr/bin/ruby
require 'rubygems'
require 'json'
require 'eventmachine'
require 'em/buftok'
require 'meow'

require 'net/http'

require 'twitter_stream'

AUTH = 'USER:PASSWORD'
SEARCH = 'sxsw'

meow = Meow.new('Growter', 'Note', Meow.import_image('twitter.png'))

Dir.mkdir 'avatarcache' unless File.exists?('avatarcache')

EventMachine::run {
  stream = TwitterStream.connect(
      :content => "track=#{SEARCH}",
      :auth => AUTH
  )
    
  stream.each_item do |msg|
    tweet = JSON.load(msg)
    screen_name = tweet['user']['screen_name']
    
    unless File.exists?("avatarcache/#{screen_name}.png")
      Net::HTTP.start("img.tweetimag.es") { |http|
        resp = http.get("/i/#{screen_name}_n")
        open("avatarcache/#{screen_name}.png", "wb") { |file|
          file.write(resp.body)
         }
      }
    end
    
    meow.notify "#{tweet['user']['name']} (#{screen_name})", tweet['text'], :icon => "avatarcache/#{screen_name}.png" do
      system "open http://twitter.com/#{screen_name}/statuses/#{tweet['id']}"
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