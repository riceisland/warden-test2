require 'resque'
require './app2'

class DataRefresh

  @queue = :data_refresh
  
  def self.perform(user_id)

  twitter_oauth = Twitter_oauth.where(:uid => user_id).first
  
  if twitter_oauth    
    twitter_db_create(twitter_oauth.twitter_access_token, twitter_oauth.twitter_access_token_secret)
  end
  
#tumblr

  tumblr_oauth = Tumblr_oauth.where(:uid => user_id).first
  
  if tumblr_oauth  
    tumblr_db_create(tumblr_oauth.tumblr_access_token, tumblr_oauth.tumblr_access_token_secret)
  end
  
#instagram

  instagram_oauth = Instagram_oauth.where(:uid => user_id).first
  
  if instagram_oauth
    instagram_db_create(instagram_oauth.instagram_access_token)
  end

#evernote

  evernote_oauth = Evernote_oauth.where(:uid => user_id).first
  
  if evernote_oauth  
    evernote_db_create(evernote_oauth.evernote_access_token, evernote_oauth.evernote_shard_id)
  end

#hatena

  hatena_oauth = Hatena_oauth.where(:uid => user_id).first
  
  if hatena_oauth 
    hatena_db_create(hatena_oauth.hatena_access_token,hatena_oauth.hatena_access_token_secret)
  end

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
  
  end


end