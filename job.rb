#! ruby -Ku
# -*- coding: utf-8 -*-
require 'resque'
require 'nokogiri'
#require 'net/https'
require 'parallel'
require './app2'
require "./extract"

module DataRefresh

  @queue = :data_refresh
 
  def self.perform(user_id)

#twitter
 
    twitter_oauth = Twitter_oauth.where(:uid => user_id).first
    twitter_data = TwitterData::TwitterData.new(user_id, twitter_oauth.twitter_access_token, twitter_oauth.twitter_access_token_secret)
    twitter_data.twitter_db_create()
 
#tumblr

    tumblr_oauth = Tumblr_oauth.where(:uid => user_id).first
    tumblr_data = TumblrData::TumblrData.new(current_user.id, tumblr_oauth.tumblr_access_token, tumblr_oauth.tumblr_access_token_secret)
    tumblr_data.tumblr_db_create()
  
#flickr
    flickr_oauth = Flickr_oauth.where(:uid => user_id).first
    flickr_data = FlickrData::FlickrData.new(current_user.id, flickr_oauth.flickr_access_token, flickr_oauth.flickr_access_token_secret)
    flickr_data.flickr_db_create() 

#instagram

    instagram_oauth = Instagram_oauth.where(:uid => user_id).first
    instagram_data = InstagramData::InstagramData.new(current_user.id, instagram_oauth.instagram_access_token)
    instagram_data.instagram_db_create()

#hatena

    hatena_oauth = Hatena_oauth.where(:uid => user_id).first
    hatena_data = HatenaData::HatenaData.new(current_user.id)
    hatena_data.hatena_db_create(hatena_oauth.hatena_access_token,hatena_oauth.hatena_access_token_secret)
  
#evernote

    evernote_data = EvernoteData::EvernoteData.new(current_user.id)
    evernote_data.evernote_db_create()
 
    puts "Processed a job!" 
  
=begin 
#rss
#uidはどこへいったの？？？
  channels = Rss_user_relate.group(:channel_id).having('count(channel_id) > 0').all;
    
  channel_list = Array.new
        
  channels.each do |elem|
    channel_id = elem.values[:channel_id]

    channel_data = Rss_channel.filter(:channel_id => channel_id)

    channel_data.each do |elem|
      arr = [elem.channel_id, elem.link]
      channel_list.push(arr)
    end  
  end
  
  channel_list.each do |elem|
    
    begin
      feed = FeedNormalizer::FeedNormalizer.parse(open(elem[1]))       
    rescue
      p "error"
    end

    feed.entries.reject{|x|x.title=~/^PR:/}.map{|e|
      rss_db_create(e, elem[0])
    }
  end
=end  
  end

end


module DataCreate

  @queue = :data_create
  
  def self.perform(user_id, app, token, secret)
  
    case app
    when "twitter"
    
      twitter_data = TwitterData::TwitterData.new(current_user.id, token, secret)
      twitter_data.twitter_db_create() 
    
    when "flickr"
    
      flickr_data = FlickrData::FlickrData.new(current_user.id, token, secret)
      flickr_data.flickr_db_create()
    
    end
    
  end
  
end

module BookmarkDataCreate

  @queue = :bookmark_data_create
  
  def self.perform(user_id, file)
    
    doc = Nokogiri::HTML(file)

    extractor = ExtractContent::Extractor.new
  
    Parallel.each(doc.css("a"), in_threads:8){|elem| 
     
      if elem["href"] =~ /\Ahttps?\:\/\//
      
        begin
          description = extractor.analyse(open(elem["href"]).read)[0]    
          #p description
          
        rescue
          description = ""
        
        end
      
        unless description == ""
       
          str =  description.split(//)
          len = str.length
        
          if len > 200
            new_str = str.slice(0, 200)
            description = new_str.join("")
          end
        
        end
    
        Browser_bookmarks.create({
          :user_id => user_id,
          :title => elem.content,
          :url => elem["href"],
          :description => description,
          :issued => Time.at(elem["add_date"].to_i),
          :refrection => 0,
        })
    
      end

   }

  end


end
