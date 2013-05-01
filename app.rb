#! ruby -Ku
# -*- coding: utf-8 -*-
require "sinatra"
require "warden"
require "sequel"
require "openssl"
require "haml"
require 'oauth'
require 'twitter'
require 'tumblife'
require 'multi_json'
require 'net/https'
require 'instagram'
require 'open-uri'
require 'nokogiri'
require 'will_paginate'
require 'will_paginate/sequel'
require 'feed-normalizer'
require 'kconv'
require 'json'
require "sinatra/reloader" if development?

#evernote用
require "./evernote_config"

require "./model.rb"

# Sinatra のセッションを有効にする
set :public_folder, File.join(File.dirname(__FILE__) , %w{ . public })
use Rack::Session::Cookie, :secret => Digest::SHA1.hexdigest(rand.to_s)
#enable :static

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
  
  def warden
    request.env['warden']
  end
  
  def current_user
    warden.user
  end
end

#instagram用
CALLBACK_URL = "http://localhost:4567/instagram_callback"
#CALLBACK_URL = "http://java.slis.tsukuba.ac.jp/log-ref/instagram_callback"

#twitter,tumblr,instagram key,secret
configure do

  TWITTER_KEY = "kKw2qK1VOmPvycg6RVTiA"
  TWITTER_SECRET = "LTSCjG2Fkj5TUbsFIaFeEcDDIjDQwuBzHem9BLlk"
  
  TUMBLR_KEY = "oJ2eYbl0jdzCB0PZY3oDgR2jkkfB3s1buxzIRCbTWuMqMjxYv0"
  TUMBLR_SECRET = "MFCzA1Db7utdAmj0S8ycmwzrTVcV5w1InYZNcy05Usrk3nkEMk"
  
  INSTAGRAM_KEY = "46e304415ae2408e85bd2ca3b78d4903"
  INSTAGRAM_SECRET = "db8c0297bb4b4a2db278134a4892ffb9"
  
end

def configure_twitter_token(token, secret)
  Twitter.configure do |config|
    config.consumer_key = TWITTER_KEY
	config.consumer_secret = TWITTER_SECRET
    config.oauth_token = token
    config.oauth_token_secret = secret
  end
end

def configure_tumblr_token(token, secret)
  Tumblife.configure do |config|
    config.consumer_key = TUMBLR_KEY
	config.consumer_secret = TUMBLR_SECRET
	config.oauth_token = token
	config.oauth_token_secret = secret
  end
end

Instagram.configure do |config|
  config.client_id = INSTAGRAM_KEY
  config.client_secret = INSTAGRAM_SECRET
end

def shorten(long_url)
  id = 'riceisland'
  api_key = 'R_aa5bc27c2693d26e9238164ec7f95ef8'
  version = '2.0.1'
  
  query = "version=#{version}&longUrl=#{long_url}&login=#{id}&apiKey=#{api_key}"
  result = JSON,(Net::HTTP.get("api.bit.ly", "/shorten?#{query}"))
  result['results'].each_pair {|long_url, value|
    return value['shortUrl']
  }
end

before do
  @title = "まとめてらんだむ"
  #@prefix = "/mat_rnd"
  #@prefix = env["prefix"]

end

def base_url
  default_port = (request.scheme == "http") ? 80 : 443
  port = (request.port == default_port) ? "" : ":#{request.port.to_s}"
  "#{request.scheme}://#{request.host}#{port}"
end

def twitter_oauth_consumer
  return OAuth::Consumer.new(TWITTER_KEY, TWITTER_SECRET, :site => "https://twitter.com")
end

def tumblr_oauth_consumer
  OAuth::Consumer.new(TUMBLR_KEY, TUMBLR_SECRET, {site:  "http://www.tumblr.com"})
end

def hatena_oauth_consumer
  return OAuth::Consumer.new(
    'CPplvRerEF3f5A==',
    'YtKTcjMlCfaOhVppKt0FNXVKZMI=',
    :site               => '',
    :request_token_path => 'https://www.hatena.com/oauth/initiate',
    :access_token_path  => 'https://www.hatena.com/oauth/token',
    :authorize_path     => 'https://www.hatena.ne.jp/oauth/authorize')	
end

def evernote_oauth_consumer
  return OAuth::Consumer.new(
    OAUTH_CONSUMER_KEY, 
    OAUTH_CONSUMER_SECRET,{
    :site => EVERNOTE_SERVER,
    :request_token_path => "/oauth",
    :access_token_path => "/oauth",
    :authorize_path => "/OAuth.action"})
end

def rand_id_sample(app)

  content_ids = Array.new()
    
  case app
    when "twitter_f"
      ids = Twitter_favorites.select(:data_id).filter(:user_id => current_user.id)

    when "twitter_h"
      ids = Tweets.select(:data_id).filter(:user_id => current_user.id)
    
    when "tumblr"
      ids = Tumblr_posts.select(:data_id).filter(:user_id => current_user.id)
    
    when "instagram"
      ids = Instagram_photos.select(:data_id).filter(:user_id => current_user.id)
    
    when "hatena"
      ids = Hatena_bookmarks.select(:data_id).filter(:user_id => current_user.id)    
      
    when "evernote"
      ids = Evernote_notes.select(:data_id).filter(:user_id => current_user.id)
    
    when "rss"    
      ids = Rss_user_relate.select(:data_id).filter(:user_id => current_user.id)
    else
  end
  		
  ids.each do |id|
	content_ids.push(id.data_id)
  end
	
  rand_id = content_ids.sample
  #rand_id = "276189947369775105"
  
  return rand_id

end

def twitter_home_data_create(id)
  
  ref_count = ref_counter("twitter_h", id)
	 
  @twitter.user_timeline(:count=> 1, :max_id => id).each do |fav|
    
    @twitter_img_url = fav.user.profile_image_url 
    @twitter_user_name = fav.user.name
    @twitter_screen_name = fav.user.screen_name
    @twitter_text = fav.text
    @twitter_time = fav.created_at
	 # @twitter_long_url = 'https://twitter.com/_/status/' + @rand_fav_id.to_s
	  #@short_url = shorten(@long_url)
  end
    
  data_hash = {:app => "twitter_h", :twitter_img_url => @twitter_img_url, :twitter_user_name => @twitter_user_name, :twitter_screen_name => @twitter_screen_name, :twitter_text => @twitter_text, :twitter_time => @twitter_time, :tag_concat => tag_concat(id), :tag_array => tag_array(id), :id => id, :ref_count => ref_count }
    
  return data_hash

end


def twitter_favs_data_create(id)
  
  ref_count = ref_counter("twitter_f", id)
	 
  @twitter.favorites(:count=> 1, :max_id => id).each do |fav|
    
    @twitter_img_url = fav.user.profile_image_url 
    @twitter_user_name = fav.user.name
    @twitter_screen_name = fav.user.screen_name
    @twitter_text = fav.text
    @twitter_time = fav.created_at
	 # @twitter_long_url = 'https://twitter.com/_/status/' + @rand_fav_id.to_s
	  #@short_url = shorten(@long_url)
  end
    
  data_hash = {:app => "twitter_f", :twitter_img_url => @twitter_img_url, :twitter_user_name => @twitter_user_name, :twitter_screen_name => @twitter_screen_name, :twitter_text => @twitter_text, :twitter_time => @twitter_time, :tag_concat => tag_concat(id), :tag_array => tag_array(id), :id => id, :ref_count => ref_count }
    
  return data_hash

end

def tumblr_data_create(id)

  ref_count = ref_counter("tumblr", id)
        
  blogurl = @tumblr.info.user.blogs[0].url
  blogurl.gsub!('http://', '')
    
  post = @tumblr.posts(blogurl, {:id => id}).posts[0]
  
  time = post.date    
  type = post.type
  tags = post.tag
    
  content = {:app => "tumblr", :id => id, :type => type, :tumblr_time => time, :tag_concat => tag_concat(id), :tag_array => tag_array(id), :ref_count => ref_count}
    
  case type
    when "text"
      content.store(:post_title, post.title)
      content.store(:body, post.body)
    when "photo" 
      layouts = post.photoset_layout
      if layouts
         layout = layouts.to_s.split("")
      end
      content.store(:imgarr, post.photos)
      content.store(:caption, post.caption)
      content.store(:layouts, layouts)
      content.store(:layout, layout)
    when "quote"
      content.store(:text, post.text)
      content.store(:source, post.source)
    when "link"
      content.store(:post_title, post.title)
      content.store(:url, post.url)
      content.store(:description, post.description)
    when "chat"
      content.store(:post_title, post.title)
      content.store(:dialogue, post.dialogue)    
    when "audio"
      content.store(:code, post.embed_code)
      content.store(:caption, post.caption)
    when "video"
      code = post.player[2].embed_code 
      content.store(:blogtitle, post.blogname)   
      content.store(:code, code)
      content.store(:caption, post.caption)    
    else
  end 
  
  return content

end

def instagram_data_create(id)

  ref_count = ref_counter("instagram", id)
  
  begin 
  photo = @instagram.media_item(id)
  instagram_img_url = photo.images.low_resolution

  instagram_time = photo.created_time
  instagram_time = Time.at(instagram_time.to_i).to_s
	
  if photo.caption
    instagram_tags = photo.tags #array  
    instagram_text = photo.caption.text
  else
    instagram_tags = nil
    instagram_text = nil
  end

  data_hash = {:app => "instagram", :instagram_img_url => instagram_img_url, :instagram_tags => instagram_tags, :instagram_time => instagram_time, :instagram_text => instagram_text, :tag_concat => tag_concat(id), :tag_array => tag_array(id), :id => id, :ref_count => ref_count }
  
  return data_hash
  
  rescue
  
  end
  
  
end

def hatena_data_create(id)

  ref_count = ref_counter("hatena", id)
    
  bookmark = Hatena_bookmarks.filter(:data_id => id)
    
  bookmark.each do |elem|
    @hatena_title = elem.title
    @hatena_url = elem.url
    @hatena_issued = elem.issued
  end 

  data_hash = {:app => "hatena", :hatena_title => @hatena_title, :hatena_url => @hatena_url, :hatena_issued => @hatena_issued, :tag_concat => tag_concat(id), :tag_array => tag_array(id), :id => id, :ref_count => ref_count }
  
  return data_hash

end

def evernote_data_create(id)

  ref_count = ref_counter("evernote", id)
	  
  noteStoreUrl = NOTESTORE_URL_BASE + @evernote_oauth.evernote_shard_id
  noteStoreTransport = Thrift::HTTPClientTransport.new(noteStoreUrl)
  noteStoreProtocol = Thrift::BinaryProtocol.new(noteStoreTransport)
  noteStore = Evernote::EDAM::NoteStore::NoteStore::Client.new(noteStoreProtocol)    
	 
  note = noteStore.getNote(@evernote_oauth.evernote_access_token, id ,true,true,true,true)
  @note_title = note.title.force_encoding("UTF-8")
  @content = note.content
  @content.force_encoding("UTF-8")
	    
  resources_reg = @content.scan(/<en-media.*hash=\"(.*?)\"/)
	    
  resources_reg.each do |reg|
  note.resources.each do |resource|
    resource_hash = resource.data.bodyHash.unpack('H*').first
	  @guid = resource.guid
	
	  attribute = noteStore.getResourceAttributes(@evernote_oauth.evernote_access_token, @guid)
	        
	  @fileName = attribute.fileName.force_encoding("UTF-8")
	   
	  ext = case resource.mime
	    when 'image/png'
	       'png'
	    when 'image/jpg'
           'jpg'
        when 'image/gif'
           'gif'
        when 'audio/mpeg'
	       'mpeg'
	    when 'application/pdf'
	       'pdf'
	    else #'application/octet-stream'
	         ''
	  end
	       
	  if resource_hash == reg[0]
	         
	    case ext
	      when 'png' || 'jpg' || 'gif'
	        @replace =  "<img src='https://sandbox.evernote.com/shard/s1/res/" + @guid + "." + ext + "'>" 
	      when 'pdf'
	         @href = "<a href='https://sandbox.evernote.com/shard/s1/res/"+ @guid + "/" + @fileName + "." + ext  +"' target='_blank'>" 
	         @replace = @href + "<img src='https://sandbox.evernote.com/images/file-generic.png'>" + @fileName + "</a>"
	      when 'mpeg'
	         @replace = "<embed src='https://sandbox.evernote.com/shard/s1/res/" + @guid + "/" + @fileName + "'>"
	      else #'application/octet-stream'
	         @href = "<a href='https://sandbox.evernote.com/shard/s1/res/"+ @guid + "/" + @fileName + "." + ext  +"'>" 
	         @replace = @href + "<img src='https://sandbox.evernote.com/images/file-generic.png'>" + @fileName + "</a>"
	    end
	
	    @content.sub!(/<\/en-media>/, "")
	    @content.sub!(/<en-media.*?>/, @replace)
	        
	  end     
	end
  end
	     
  content_snippet = note.content.gsub(/<.*?>/, "")
  str =  content_snippet.split(//)
	
  i=2
  @snippet = ""
  while i < 300
    if str[i]
      @snippet = @snippet + str[i]
      i = i + 1
    else
	  break
	end
  end 
	      
  #default: 2012-09-03 15:24:24 +0900
  @create_time = Time.at(note.created / 1000).to_s
  @create_date = @create_time.split(/ /)[0]
	      
  @link = "https://sandbox.evernote.com/Home.action#n=" + note.guid.to_s 
	  
  data_hash = {:app => "evernote", :note_title => @note_title, :content => @content, :snippet => @snippet, :link => @link, :tag_concat => tag_concat(id), :tag_array => tag_array(id), :id => id, :ref_count => ref_count, :evernote_time => @create_time }
  
  return data_hash

end

def rss_data_create(id)

  ref_count = ref_counter("rss", id)
    
  item = Rss_item.filter(:data_id => id)
    
  item.each do |elem|
    @rss_title = elem.title
    @rss_url = elem.url
    @rss_date = elem.date
    @rss_description = elem.description
  end 
    
  data_hash = {:app => "rss", :rss_title => @rss_title, :rss_url => @rss_url, :rss_date => @rss_date, :rss_description => @rss_description, :tag_concat => tag_concat(id), :tag_array => tag_array(id), :id => id, :ref_count => ref_count }
  
  return data_hash

end

def db_row_create(app, id)
  
  case app
    when "twitter_f"
      Twitter_favorites.create({
	    :user_id => current_user.id,
		:data_id => id,
		:refrection => 0,
	  })
	when "twitter_h"
	   Tweets.create({
	     :user_id => current_user.id,
		 :data_id => id,
	     :refrection => 0,
	   })
	 when "tumblr"
       Tumblr_posts.create({
         :user_id => current_user.id,
         :data_id => id,
         :refrection => 0,
       })
     when "instagram"
       Instagram_photos.create({
         :user_id => current_user.id,
         :data_id => id,
         :refrection => 0,
       })
             
     when "evernote"	 
       Evernote_notes.create({
         :user_id => current_user.id,
         :data_id => id,
         :refrection => 0,
       })
  end
end

def db_tag_create(app, id, tag)
  time = Time.now.to_s
  
  Tags.create({
    :user_id => current_user.id,
    :data_id => id,
    :tag => tag,
    :time => time,
    :app => app,
  })
  
end

def rss_db_create(e, channel_id)
  past_item = Rss_item.select(:data_id).filter(:url => e.url).first
  #p past_item
  
  unless past_item       
    Rss_item.create({
      :channel_id => channel_id,
      :title => e.title.toutf8,
      :url => e.url,
      :date => e.date_published.to_s,
      :description => e.description.toutf8,
    })          
  end
     
  this_data = Rss_item.select(:data_id).filter(:url => e.url).first

  past_relate_id = Rss_user_relate.select(:data_id).filter(:user_id => current_user.id, :data_id => this_data.data_id).first
     
  unless past_relate_id
    #p this_data.data_id
    Rss_user_relate.create({
      :user_id => current_user.id,
      :data_id => this_data.data_id,
      :refrection => 0,
      :channel_id => channel_id,
    })
  end

end

def ref_counter(app, id)

  case app
    when "twitter_f"
      ref_sql = Twitter_favorites.select(:refrection).filter(:data_id => id)
    
    when "twitter_h"
      ref_sql = Tweets.select(:refrection).filter(:data_id => id)
    
    when "tumblr"
      ref_sql = Tumblr_posts.select(:refrection).filter(:data_id => id)
    
    when "instagram"
      ref_sql = Instagram_photos.select(:refrection).filter(:data_id => id)
    
    when "hatena"
      ref_sql = Hatena_bookmarks.select(:refrection).filter(:data_id => id)
    
    when "evernote"
      ref_sql = Evernote_notes.select(:refrection).filter(:data_id => id)
      
    when "rss"
      ref_sql = Rss_user_relate.select(:refrection).filter(:data_id => id)
    else
  end
  
  ref_sql.each do |ref|
	ref_count = ref.refrection
	return ref_count
  end 
  
end

def tag_array(data_id)
  tags = Tags.select(:tag).filter(:user_id => current_user.id, :data_id => data_id) 
  tag_array = Array.new
  
  tags.each do |tag|
    tag_array.push(tag.tag)
  end
  
  return tag_array
end

def tag_concat(data_id)
  tags = Tags.select(:tag).filter(:user_id => current_user.id, :data_id => data_id) 
  tag_concat = ""
  
  tags.each do |tag|
    tag_concat = tag_concat + tag.tag + ","
  end
  tag_concat.chop!
  
  return tag_concat
end

def tag_a_concat(data_id)
  tags = Tags.select(:tag).filter(:user_id => current_user.id, :data_id => data_id) 
  tag_a_concat = ""
  tags.each do |tag|
    tag_html = "<a href= /" + tag.tag + ">" + tag.tag + "</a> "  
    tag_a_concat = tag_a_concat + tag_html
  end
  return tag_a_concat
end

def tag_recreate(id, tags, app)
  Tags.filter(:user_id => current_user.id, :data_id => id).delete
   
  split_tag = tags.split(",")
   
  split_tag.each do |elem|
    elem.gsub!(/\s/, "")
    db_tag_create(app, id, elem)
  end
end

def one_data_create(app, id)
  
  if id == ""
    p app
    id = rand_id_sample(app)
  end

  case app
    when "twitter_f"
      
      twitter_oauth = Twitter_oauth.where(:uid => current_user.id).first
 
      configure_twitter_token(twitter_oauth.twitter_access_token, twitter_oauth.twitter_access_token_secret)
      @twitter = Twitter::Client.new
        
      data_hash = twitter_favs_data_create(id)
          
    when "twitter_h"
      
      twitter_oauth = Twitter_oauth.where(:uid => current_user.id).first
 
      configure_twitter_token(twitter_oauth.twitter_access_token, twitter_oauth.twitter_access_token_secret)
      @twitter = Twitter::Client.new
        
      data_hash = twitter_home_data_create(id)
      
    when "tumblr"
      
      tumblr_oauth = Tumblr_oauth.where(:uid => current_user.id).first

      configure_tumblr_token(tumblr_oauth.tumblr_access_token, tumblr_oauth.tumblr_access_token_secret)
      @tumblr = Tumblife.client
      
      data_hash = tumblr_data_create(id)
       
    when "instagram"
      
      instagram_oauth = Instagram_oauth.where(:uid => current_user.id).first

      @instagram = Instagram.client(:access_token => instagram_oauth.instagram_access_token)
    
	  data_hash = instagram_data_create(id)
      
    when "hatena"

      data_hash = hatena_data_create(id)
      
    when "evernote"
      
      @evernote_oauth = Evernote_oauth.where(:uid => current_user.id).first
      data_hash = evernote_data_create(id)
      
    when "rss"
            
      data_hash = rss_data_create(elem.data_id)
          
    else
          
  end
  return data_hash

end

def twitter_db_create(token,secret) 

  configure_twitter_token(token, secret)
  @twitter = Twitter::Client.new
  
  begin
      
    @twitter.favorites(:count => 100).each do |twit|
 
      past_fav = Twitter_favorites.select(:id).filter(:user_id => current_user.id, :data_id => twit.id)

      if past_fav.empty?
        db_row_create("twitter_f", twit.id)
	  else
	    break
	  end
	        
    end  #--each do
     
    @twitter.user_timeline(:count => 200).each do |twit|
   
      past_tweet = Tweets.select(:id).filter(:user_id => current_user.id, :data_id => twit.id)

      if past_tweet.empty?
        db_row_create("twitter_h", twit.id)
      else
	    break
	  end
	        
    end  #--each do
    
  rescue Twitter::Error::Unauthorized => error
	  
	if error.to_s.index("Invalid or expired token")
      reject("twitter")
    end
	  
  rescue Twitter::Error::Forbidden => error	    
	
  end
  
end

def tumblr_db_create(token,secret)   

  configure_tumblr_token(token, secret)
  tumblr = Tumblife.client
    
  info = tumblr.info
  blogurl = info.user.blogs[0].url
  blogurl.gsub!('http://', '')
    
  offset = 0
  limit = 20
    
  begin
    
  catch(:tumblr_exit){
    begin
      res = tumblr.posts(blogurl, {:offset => offset, :limit => limit})

      res.posts.each do |post|
      
        past_post = Tumblr_posts.select(:id).filter(:user_id => current_user.id, :data_id => post.id)
      
        if past_post.empty?
          db_row_create("tumblr", post.id)
            
          post.tags.each do |tag|
            db_tag_create("tumblr", post.id, tag)                            
          end
            
        else
          throw :tumblr_exit
        end
        
      end
      offset += limit      
    end while offset < res.total_posts
  }
    
  rescue
    p "error!"
  end

end

def instagram_db_create(token) 
  instagram = Instagram.client(:access_token => token)
    
  instagram.user_recent_media.each do |photo|
    
    past_photo = Instagram_photos.select(:id).filter(:user_id => current_user.id, :data_id => photo.id)
      
    if past_photo.empty?
      db_row_create("instagram", photo.id)  
        
      if photo.tags #array
               
        photo.tags.each do |tag|   
          db_tag_create("instagram", photo.id, tag)            
        end            
      end
        
    else
      break
    end
  end
  
end

def evernote_db_create(token, shard_id)

  noteStoreUrl = NOTESTORE_URL_BASE + shard_id
  noteStoreTransport = Thrift::HTTPClientTransport.new(noteStoreUrl)
  noteStoreProtocol = Thrift::BinaryProtocol.new(noteStoreTransport)
  noteStore = Evernote::EDAM::NoteStore::NoteStore::Client.new(noteStoreProtocol)
    
  notebooks = noteStore.listNotebooks(token)
      
  filter = Evernote::EDAM::NoteStore::NoteFilter.new
  filter.words = ""
   
  spec = Evernote::EDAM::NoteStore::NotesMetadataResultSpec.new(
    includeTitle: false,
    includeContentLength: false,
    includeCreated: false,
    includeUpdated: false,
    includeUpdateSequenceNum: false,
    includeNotebookGuid: false,
    includeTagGuids: true,
    includeAttributes: true,
    includeLargestResourceMime: false,
    includeLargestResourceSize: false,
  )
      
  offset = 0
  pageSize = 10
  
  begin
    
    catch(:evernote_exit){
      begin      
      res = noteStore.findNotesMetadata(token, filter, offset, 10, spec)
      
      i = res.notes.length
      while i > 0 
      
        i = i - 1      
        past_note = Evernote_notes.select(:id).filter(:user_id => current_user.id, :data_id => res.notes[i].guid)
      
        if past_note.empty?
          db_row_create("evernote", res.notes[i].guid)
       
          evernote_tags = res.notes[i].tagGuids
          if evernote_tags
            evernote_tags.each do |tag_id|
              tag_resource = noteStore.getTag(evernote_oauth.evernote_access_token, tag_id)
              tag = tag_resource.name.force_encoding("UTF-8")
              db_tag_create("evernote", res.notes[i].guid, tag)

            end  #-- evernote_tags.each
          end #--if evernote_tags
          
        else
          throw :evernote_exit
        end #-- if past_note.empty?          
       
      end #-- while
    
      offset = offset + pageSize
    
    end while res.totalNotes > offset
    
    } #-- catch
    
  rescue Evernote::EDAM::Error::EDAMUserException => e
	#再認証が必要
	if e.errorCode == 9
	  reject("evernote")
    end

  end

end

def hatena_db_create(token, secret)

  hatena = OAuth::AccessToken.new(hatena_oauth_consumer,token,secret)
    
  request_url = 'http://b.hatena.ne.jp/atom/feed?of=0' 
    
  begin
     
    catch(:hatena_exit){  
      while true
        response = hatena.request(:get, request_url)
  
        xml_doc = Nokogiri::XML(response.body)
        xml_doc.css("entry").each do |elem|
          entry_doc = Nokogiri::XML(elem.to_html)
          id = entry_doc.css("id")[0].content
        
          past_bookmark = Hatena_bookmarks.select(:id).filter(:user_id => current_user.id, :id => id)
        
          if past_bookmark.empty?
          
            title = entry_doc.css("title")[0].content
            issued = entry_doc.css("issued")[0].content
            name = entry_doc.css("name")[0].content
            comment = entry_doc.css("summary")[0].content
            url = entry_doc.xpath("//*[@rel='related']")[0].attribute("href").value 
         
            entry_doc.xpath("//dc:subject", "dc" => 'http://purl.org/dc/elements/1.1/').each do |elem|
              db_tag_create("hatena", id, elem.content)
            end #--entry_coc.xpath().each
  
            Hatena_bookmarks.create({
              :user_id => current_user.id,
              :data_id => id,
              :name => name,
              :title => title,
              :issued => issued,
              :url => url,
              :comment => comment,
              :refrection => 0,
            })
          
          else
            throw :hatena_exit
          end #--if past_bookmark
       
          rel_next = xml_doc.xpath("//*[@rel='next']")[0]
          
          if rel_next
           request_url = xml_doc.xpath("//*[@rel='next']")[0].attribute("href").value
          else
            #request_url = ""
            #break
            throw :hatena_exit
          end
      
        end #--xml_doc.css().each 
       
      end #--while true
    } #--catch
    
  rescue => e
    #もし認証が切れた場合は強制reject操作しておく
    if e.message == "token_rejected"
      reject("hatena")     
    end
    
  end

end

def reject(app)

  case app
    when "twitter"
      Twitter_oauth.where(:uid => current_user.id).delete
      Twitter_favorites.where(:user_id => current_user.id).delete
      Tweets.where(:user_id => current_user.id).delete
      Tags.where(:user_id => current_user.id, :app => "twitter_f").delete
      Tags.where(:user_id => current_user.id, :app => "twitter_h").delete
      
	when "tumblr"
	  Tumblr_oauth.where(:uid => current_user.id).delete
	  Tumblr_posts.where(:user_id => current_user.id).delete
	  Tags.where(:user_id => current_user.id, :app => "tumblr").delete
      
	when "instagram"
	  Instagram_oauth.where(:uid => current_user.id).delete
	  Instagram_photos.where(:user_id => current_user.id).delete
	  Tags.where(:user_id => current_user.id, :app => "instagram").delete
	   
	when "hatena"
	  Hatena_oauth.where(:uid => current_user.id).delete
	  Hatena_bookmarks.where(:user_id => current_user.id).delete
	  Tags.where(:user_id => current_user.id, :app => "hatena").delete
	  
	when "evernote"
	  Evernote_oauth.where(:uid => current_user.id).delete
	  Evernote_notes.where(:user_id => current_user.id).delete
	  Tags.where(:user_id => current_user.id, :app => "evernote").delete
	else
  end  

end

# 認証方式を登録。

Warden::Strategies.add :login_test do
  # 認証に必要なデータが送信されているか検証
  def valid?
    params["name"] || params["password"]
  end

  # 認証
  def authenticate!
    hexpass = OpenSSL::Digest::SHA1.hexdigest(params["password"])
    user = User.authenticate(params["name"], hexpass)
    
    user.nil? ? fail!('Could not log in') : success!(user, 'Successfully logged in')

  end
end

Warden::Manager.before_failure do |env,opts|
  env['REQUEST_METHOD'] = 'POST'
end

# Warden の設定
use Warden::Manager do |manager|
  # 先ほど登録したカスタム認証方式をデフォルトにする
  manager.default_strategies :login_test

  # 認証に失敗したとき呼び出す Rack アプリを設定(必須)
  manager.failure_app = Sinatra::Application
  
  # ユーザー ID をもとにユーザー情報を取得する
  Warden::Manager.serialize_from_session{|id| User[id] }
 
  # ユーザー情報からセッションに格納する ID を取り出す
  Warden::Manager.serialize_into_session{|user| user.id}

end

# ログインしていないときは、ログインフォームを表示。
# ログインしているときは、ログイン済ページを表示。
get "/" do
  if request.env["warden"].user.nil?
  	@menu = Array.new
    @menu.push(["login", "c"])
    @menu.push(["register", "c"])
    #erb :login
    haml :top
  else
    redirect to ('/main')
  end
end

# 認証を実行する。
# 成功すれば設定ページに移動。
post "/login" do
  request.env["warden"].authenticate!
  redirect to ("/data_refresh")
end

#get-login（URL直打ちパターン）
get "/login" do  
  if request.env["warden"].user.nil?
  
    @menu = Array.new
    @menu.push(["login", "d"])
    @menu.push(["register", "c"])

    haml :login
  else   
	redirect to ("/main")
  end
end


# 認証に失敗したとき呼ばれるルート。
# ログイン失敗ページを表示してみる。
#redirectで吹っ飛ばす推奨
post "/unauthenticated" do
  
  @menu = Array.new
  @menu.push(["login", "d"])
  @menu.push(["register", "c"])
  #erb :fail_login
  haml :fail_login
end

# ログアウトする。
# ログアウト後はトップページに移動。
get "/logout" do
  request.env["warden"].logout
  redirect to ("/")
end

get "/register" do
  if request.env["warden"].user.nil?
    @menu = Array.new
    @menu.push(["login", "c"])
    @menu.push(["register", "d"])

    haml :register
  else
    redirect to ("/main")
  end
end

post "/register" do
  if params[:name] && params[:password] && params[:re_password] && params[:mail]
    if params[:password] == params[:re_password]
      hexpass = OpenSSL::Digest::SHA1.hexdigest(params["password"])
      User.create({
	    :name => params[:name],
       :password => hexpass,
	  })
	  #登録と同時にログイン処理をしておく
	  request.env["warden"].authenticate!
      redirect to("/settings")
    else
      redirect to ("/register")
    end
  else
    redirect to ("/register")
  end
end

get "/settings" do
  if request.env["warden"].user.nil?
    redirect to ("/")
  else
	@menu = Array.new
    @menu.push(["main", "c"])
    @menu.push(["settings", "d"])
    @menu.push(["logout", "c"])
  
    @settings_array = Array.new
  
    twitter_oauth = Twitter_oauth.where(:uid => current_user.id).first
    if twitter_oauth
      @settings_array.push(["twitter", "/reject/twitter", "認証をやめる", "b"])
    else
      @settings_array.push(["twitter", "/twitter_request_token", "認証する", "e"])
    end
    
    tumblr_oauth = Tumblr_oauth.where(:uid => current_user.id).first
    if tumblr_oauth
      @settings_array.push(["tumblr", "/reject/tumblr", "認証をやめる", "b"])
    else
      @settings_array.push(["tumblr", "/tumblr_request_token", "認証する","e"])
    end
  
    instagram_oauth = Instagram_oauth.where(:uid => current_user.id).first
    if instagram_oauth
      @settings_array.push(["instagram", "/reject/instagram", "認証をやめる","b"])
    else
      @settings_array.push(["instagram", "/instagram_request_token", "認証する","e"])
    end
    
    hatena_oauth = Hatena_oauth.where(:uid => current_user.id).first
    if hatena_oauth
      @settings_array.push(["hatena", "/reject/hatena", "認証をやめる","b"])
    else
      @settings_array.push(["hatena", "/hatena_request_token", "認証する","e"])
    end
    
    evernote_oauth = Evernote_oauth.where(:uid => current_user.id).first
    if evernote_oauth
      @settings_array.push(["evernote", "/reject/evernote", "認証をやめる","b"])
    else
      @settings_array.push(["evernote", "/evernote_request_token", "認証する","e"])
    end
    
    channels = Rss_user_relate.group(:channel_id).having('count(channel_id) > 0').all;
    
    @channel_list = Array.new
        
    channels.each do |elem|
      channel_id = elem.values[:channel_id]

      channel_data = Rss_channel.filter(:channel_id => channel_id).first

      channel_hash = {:channel_id => channel_id, :title => channel_data.title}

      @channel_list.push(channel_hash)
      
    end
    
    haml :"settings"
  end
end

post "/rss_register" do

  url = params[:rss_url]
  data_hash = Hash.new
  
  begin
    feed = FeedNormalizer::FeedNormalizer.parse(open(url))
    channel_title = feed.title.force_encoding("UTF-8")
    
    past_regist = Rss_channel.where(:link => url).first
    p past_regist

    unless past_regist
      Rss_channel.create({
      	:link => url,
      	:title => channel_title,
      })
    end

    this_channel = Rss_channel.select(:channel_id).where(:link => url).first 
    
    feed.entries.reject{|x|x.title=~/^PR:/}.map{|e|
     rss_db_create(e, channel_id)
    }

    data_hash["status"] = "success" 
    data_hash["feed_title"] = feed.title.force_encoding("UTF-8")
    
    data_json = JSON.generate(data_hash)  
    
    return data_json
  rescue Errno::ECONNRESET => e
    p "..."
    retry
  rescue
    data_hash["status"] = "error"
    #p "Not Found..."
    data_json = JSON.generate(data_hash)  
    return data_json
  end
  
end

get "/data_refresh" do

  twitter_oauth = Twitter_oauth.where(:uid => current_user.id).first
  
  if twitter_oauth    
    twitter_db_create(twitter_oauth.twitter_access_token, twitter_oauth.twitter_access_token_secret)
  end
  
#tumblr

  tumblr_oauth = Tumblr_oauth.where(:uid => current_user.id).first
  
  if tumblr_oauth  
    tumblr_db_create(tumblr_oauth.tumblr_access_token, tumblr_oauth.tumblr_access_token_secret)
  end
  
#instagram

  instagram_oauth = Instagram_oauth.where(:uid => current_user.id).first
  
  if instagram_oauth
    instagram_db_create(instagram_oauth.instagram_access_token)
  end

#evernote

  evernote_oauth = Evernote_oauth.where(:uid => current_user.id).first
  
  if evernote_oauth  
    evernote_db_create(evernote_oauth.evernote_access_token, evernote_oauth.evernote_shard_id)
  end

#hatena

  hatena_oauth = Hatena_oauth.where(:uid => current_user.id).first
  
  if hatena_oauth 
    hatena_db_create(hatena_oauth.hatena_access_token,hatena_oauth.hatena_access_token_secret)
  end

#rss
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
    
#----setting refresh end  --------#  
  
  redirect to ("/settings")
  
end  

#twitter OAuth認証
get '/twitter_request_token' do
  #callback_url = "#{base_url}/log-ref/access_token"
  callback_url = "#{base_url}/oauth/twitter/callback"
  request_token = twitter_oauth_consumer.get_request_token(:oauth_callback => callback_url)

  session[:twitter_request_token] = request_token.token
  session[:twitter_request_token_secret] = request_token.secret

  redirect request_token.authorize_url
end

get '/oauth/twitter/callback' do
#get '/access_token' do

  request_token = OAuth::RequestToken.new(
    twitter_oauth_consumer, session[:twitter_request_token], session[:twitter_request_token_secret])
  
  session.delete(:twitter_request_token)
  session.delete(:twitter_request_token_secret)
  
  begin
    @access_token = request_token.get_access_token(
      {},
      :oauth_token => params[:oauth_token],
      :oauth_verifier => params[:oauth_verifier])
  rescue OAuth::Unauthorized => @exception
    return erb %{ oauth failed: <%=h @exception.message %> }
  end
  session[:twitter_access_token] = @access_token.token
  session[:twitter_access_token_secret] = @access_token.secret
  
  redirect to ('/twitter_set')
end

get "/twitter_set" do
#本来ならtwitteridで探してあったらupdate、なかったらcreateが妥当
  @twitter_oauth = Twitter_oauth.where(:uid => current_user.id).first

  if @twitter_oauth
    Twitter_oauth.filter(:uid => current_user.id).update(:twitter_access_token => session[:twitter_access_token], :twitter_access_token_secret => session[:twitter_access_token_secret])
    
  else
    #OAuth register
    Twitter_oauth.create({
      :uid => current_user.id,
      :twitter_access_token => session[:twitter_access_token],
      :twitter_access_token_secret => session[:twitter_access_token_secret] ,
    })
  end
  
    twitter_db_create(session[:twitter_access_token], session[:twitter_access_token_secret])
      
 
  
  session.delete(:twitter_access_token)
  session.delete(:twitter_access_token_secret)
  
  redirect to ("/settings") 
end

get '/tumblr_request_token' do
  @consumer = tumblr_oauth_consumer
  request_token = @consumer.get_request_token(
    :oauth_callback => 'http://127.0.0.1:4567/t_callback')
   #:oauth_callback => 'http://java.slis.tsukuba.ac.jp/log-ref/callback')

  session[:tumblr_request_token] = request_token.token
  session[:tumblr_request_token_secret] = request_token.secret

  redirect request_token.authorize_url
end

get '/t_callback' do

  request_token = OAuth::RequestToken.new(
  tumblr_oauth_consumer, session[:tumblr_request_token], session[:tumblr_request_token_secret])
  
  session.delete(:tumblr_request_token)
  session.delete(:tumblr_request_token_secret)  
    
  begin
  @access_token = request_token.get_access_token(
    :oauth_token => params[:oauth_token],
    :oauth_verifier => params[:oauth_verifier])
  rescue OAuth::Unauthorized => @exception
    return erb %{ oauth failed: <%=h @exception.message %> }
  end
  session[:tumblr_access_token] = @access_token.token
  session[:tumblr_access_token_secret] = @access_token.secret 
   redirect to ('/tumblr_set')

end
  
get "/tumblr_set" do
#本来ならidで探してあったらupdate、なかったらcreateが妥当
  @tumblr_oauth = Tumblr_oauth.where(:uid => current_user.id).first
  
  if @tumblr_oauth
    Tumblr_oauth.filter(:uid => current_user.id).update(:tumblr_access_token => session[:tumblr_access_token], :tumblr_access_token_secret => session[:tumblr_access_token_secret])

  else
    Tumblr_oauth.create({
      :uid => current_user.id,
      :tumblr_access_token => session[:tumblr_access_token],
      :tumblr_access_token_secret => session[:tumblr_access_token_secret],
    })
    
    tumblr_db_create(session[:tumblr_access_token],session[:tumblr_access_token_secret])
        
  end
  
  session.delete(:tumblr_access_token)
  session.delete(:tumblr_access_token_secret) 
  
  redirect to ("/settings") 
end

get "/instagram_request_token" do
  redirect Instagram.authorize_url(:redirect_uri => CALLBACK_URL)
end

get "/instagram_callback" do
  response = Instagram.get_access_token(params[:code], :redirect_uri => CALLBACK_URL)
  session[:instagram_access_token] = response.access_token
  redirect to ("/instagram_set")
end

get "/instagram_set" do
  @instagram_oauth = Instagram_oauth.where(:uid => current_user.id).first
  
  if @instagram_oauth
    Instagram_oauth.filter(:uid => current_user.id).update(:instagram_access_token => session[:instagram_access_token])    
 
  else
    Instagram_oauth.create({
      :uid => current_user.id,
      :instagram_access_token => session[:instagram_access_token],
    })
    
    instagram_db_create(session[:instagram_access_token])

  end
 
  session.delete(:instagram_access_token)
       
  redirect to ("/settings") 
end

get "/hatena_request_token" do
  request_token = hatena_oauth_consumer.get_request_token(
    { :oauth_callback => 'http://localhost:4567/hatena_callback' },
   #{ :oauth_callback => 'http://java.slis.tsukuba.ac.jp/log-ref/hatena_callback' }, 
    :scope          => 'read_public,write_public')

  # セッションへリクエストトークンを保存しておく
  session[:hatena_request_token] = request_token.token
  session[:hatena_request_token_secret] = request_token.secret

  # 認証用URLにリダイレクトする
  redirect request_token.authorize_url
end

get "/hatena_callback" do
  request_token = OAuth::RequestToken.new(
    hatena_oauth_consumer,
    session[:hatena_request_token],
    session[:hatena_request_token_secret])

  # リクエストトークンとverifierを用いてアクセストークンを取得
  access_token = request_token.get_access_token(
    {},
    :oauth_verifier => params[:oauth_verifier])

  session.delete(:hatena_request_token)
  session.delete(:hatena_request_token_secret)

  # アクセストークンをセッションに記録しておく
  session[:hatena_access_token] = access_token.token
  session[:hatena_access_token_secret] = access_token.secret

  redirect to ("/hatena_set")
end

get "/hatena_set" do
  @hatena_oauth = Hatena_oauth.where(:uid => current_user.id).first
  
  if @hatena_oauth
    Hatena_oauth.filter(:uid => current_user.id).update(:hatena_access_token => session[:hatena_access_token], :hatena_access_token_secret => session[:hatena_access_token_secret])  
    
  else
  
    Hatena_oauth.create({
      :uid => current_user.id,
      :hatena_access_token => session[:hatena_access_token],
      :hatena_access_token_secret => session[:hatena_access_token_secret],
    })
    
    hatena_db_create(session[:hatena_access_token],session[:hatena_access_token_secret])
    
  end
  
  session.delete(:hatena_access_token)
  session.delete(:hatena_access_token_secret) 
   
  redirect to ("/settings")
end

get "/evernote_request_token" do
  callback_url =  "http://localhost:4567/evernote_callback"
  #callback_url =  "http://java.slis.tsukuba.ac.jp/log-ref/evernote_callback"
  #p request.url
  
  begin
    session[:evernote_request_token] = evernote_oauth_consumer.get_request_token(:oauth_callback => callback_url)
    redirect session[:evernote_request_token].authorize_url
  rescue Exception => e
    @last_error = "Error obtaining temporary credentials: #{e.message}"
    #haml :error
  end
 
end

get "/evernote_callback" do
  if (params['oauth_verifier'].nil?)
    @last_error = "Content owner did not authorize the temporary credentials"
    #haml :error
  else
    begin
      session[:evernote_access_token] = session[:evernote_request_token].get_access_token(:oauth_verifier => params['oauth_verifier'])
      session[:shard_id] = session[:evernote_access_token].params['edam_shard']
      redirect to ('/evernote_set')
      
      session.delete(:evernote_request_token)   
      
    rescue Exception => e
      @last_error = "Failed to obtain token credentials: #{e.message}" 
      #haml :error
    end
  end
end

get "/evernote_set" do
  @evernote_oauth = Evernote_oauth.where(:uid => current_user.id).first

  if @evernote_oauth
    Evernote_oauth.filter(:uid => current_user.id).update(:evernote_access_token => session[:evernote_access_token].token, :evernote_shard_id => session[:shard_id])  
  
  else
    Evernote_oauth.create({
      :uid => current_user.id,
      :evernote_access_token => session[:evernote_access_token].token,
      :evernote_shard_id => session[:shard_id],
    })
    
    evernote_db_create(session[:evernote_access_token].token, session[:shard_id])

  end
  
  session.delete(:evernote_access_token)
  session.delete(:shard_id)

  redirect to ("/settings")  
end

get '/main' do

  if request.env["warden"].user.nil?
    redirect to ("/")
  else
    @menu = Array.new
    @menu.push(["main", "d"])
    @menu.push(["settings", "c"])
    @menu.push(["logout", "c"])


    @contents_array = Array.new 
#twitter--------------
    twitter_oauth = Twitter_oauth.where(:uid => current_user.id).first
 
    if twitter_oauth
      begin
    
        data_hash_f = one_data_create("twitter_f", "")
        data_hash_h = one_data_create("twitter_h", "")
      
        @contents_array.push(data_hash_f)
        @contents_array.push(data_hash_h)

	  rescue Twitter::Error::Unauthorized => error
	  
	    if error.to_s.index("Invalid or expired token")
          reject("twitter")
	    end
	  
	  rescue Twitter::Error::Forbidden => error
	    	
	  end
	
    end
  
#tumblr--------------

    tumblr_oauth = Tumblr_oauth.where(:uid => current_user.id).first
  
    if tumblr_oauth

      data_hash = one_data_create("tumblr", "")
      @contents_array.push(data_hash)
    
    end

#instagram--------------  
    instagram_oauth = Instagram_oauth.where(:uid => current_user.id).first
  
    if instagram_oauth

	  data_hash = one_data_create("instagram", "")
      @contents_array.push(data_hash)
  
    end

#hatena--------------  
    hatena_oauth = Hatena_oauth.where(:uid => current_user.id).first
  
    if hatena_oauth
    
      begin  
    
        data_hash = one_data_create("hatena", "")
        @contents_array.push(data_hash)
    
      rescue => e
      #もし認証が切れた場合は強制reject操作しておく
        if e.message == "token_rejected"
          reject("hatena")      
        end
    
      end
   
    end

#evernote--------------
    @evernote_oauth = Evernote_oauth.where(:uid => current_user.id).first

    if @evernote_oauth
    
      begin

        data_hash = one_data_create("evernote", "")
        @contents_array.push(data_hash)
	  
	  rescue NoMethodError => e
	    p e
	    retry
	
	  rescue Evernote::EDAM::Error::EDAMUserException => e
	 	#再認証が必要
        if e.errorCode == 9
          reject("evernote")  
	    end

      end
     
    end
  
#rss-----------------

    rss = Rss_user_relate.where(:user_id => current_user.id).first
    if rss
  
      data_hash = one_data_create("rss", "")
      @contents_array.push(data_hash)
  
    end
    
    ids = ""
    @contents_array.each do |elem|
      ids = elem[:id] + ","
    end
    
    ids.chop
    time = Time.now
    
    Main_log.create({
      :user_id => current_user.id,
      :data_id => ids,
      :time => time,
    })
   
   haml :main2
 end
end

post "/tagedit" do
 id = params[:data_id]
 if params[:twitter_f_tag_edit] 
   tag_recreate(id, params[:twitter_f_tag_edit], "twitter_f")

 elsif params[:twitter_h_tag_edit] 
   tag_recreate(id, params[:twitter_h_tag_edit], "twitter_h")
 
 elsif params[:tumblr_tag_edit] 
   tag_recreate(id, params[:tumblr_tag_edit], "tumblr")
   
 elsif params[:instagram_tag_edit] 
   tag_recreate(id, params[:instagram_tag_edit], "instagram")
   
 elsif params[:evernote_tag_edit] 
   tag_recreate(id, params[:evernote_tag_edit], "evernote")
 
 #本家のタグを合わせて更新するため分けてある
 elsif params[:hatena_tag_edit]
   tags = params[:hatena_tag_edit]
   tag_recreate(id, tags, "hatena")
    
    begin
      /([0-9]+)$/ =~ id
      eid = $1
    
    rescue
    
    #else
      
      #uri = URI.parse("http://localhost:4567")
      edituri = "http://b.hatena.ne.jp/atom/edit/" + $1
      #uri = URI.parse(edituri)
      
      tags = Tags.select(:tag).filter(:user_id => current_user.id, :data_id => id) 
      tag_concat = ""
      tags.each do |tag|
      tag_html = "[" + tag.tag + "]"  
        tag_concat = tag_concat + tag_html
      end
      
      bookmark = Hatena_bookmarks.filter(:id => id)
      comment = ""
    
      bookmark.each do |elem|
        if elem.comment
          comment = elem.comment
        end
      end 
 
      tag_comment = tag_concat + comment     
      
      content = '<entry xmlns= "http://purl.org/atom/ns#">'
      content = content + '<summary type="text/plain">'     
      content = content + tag_comment
      content = content + "</summary></entry>"
      
      hatena_oauth = Hatena_oauth.where(:uid => current_user.id).first
  
      hatena = OAuth::AccessToken.new(
      hatena_oauth_consumer,
      hatena_oauth.hatena_access_token,
      hatena_oauth.hatena_access_token_secret)

      response = hatena.put(edituri, content, {'Content-Type' =>  'application/atom+xml'})
      
     # p response.body
         
    end
 elsif params[:rss_tag_edit]     
   tag_recreate(id, params[:rss_tag_edit], "rss") 
 
 else
 
 end
 return tag_a_concat(id) 
end

post "/refrection" do
  count = params[:ref_count].to_i
  count = count + 1
  new_count = count.to_s
  
  if params[:twitter_f_data_id]
    id = params[:twitter_f_data_id]   
    Twitter_favorites.filter(:data_id => id).update(:refrection => count)
    
  elsif params[:twitter_h_data_id]
    id = params[:twitter_h_data_id]   
    Tweets.filter(:data_id => id).update(:refrection => count)
  
  elsif params[:tumblr_data_id]
    id = params[:tumblr_data_id]   
    Tumblr_posts.filter(:post_id => id).update(:refrection => count)    

  elsif params[:instagram_data_id]
    id = params[:instagram_data_id]   
    Instagram_photos.filter(:photo_id => id).update(:refrection => count)    

  elsif params[:hatena_data_id]
    id = params[:hatena_data_id]   
    Hatena_bookmarks.filter(:id => id).update(:refrection => count)
    
  elsif params[:evernote_data_id]
    id = params[:evernote_data_id]   
    Evernote_notes.filter(:note_id => id).update(:refrection => count) 
  
  elsif params[:rss_data_id]
    id = params[:rss_data_id]   
    Rss_user_relate.filter(:data_id => id).update(:refrection => count)  
              
  else
  end

  time = Time.now.to_s
  
  Reflection_log.create({
    :user_id => current_user.id,
    :data_id => id,
    :time => time,
  })  
  
  #p new_count
  return new_count
end

#getで来られたときはとりあえずランダムで対応
get "/individual" do

  if request.env["warden"].user.nil?
    redirect to ("/")
  else
  
  	@menu = Array.new
    @menu.push(["main", "c"])
    @menu.push(["settings", "c"])
    @menu.push(["logout", "c"])
    
    app_list = ["twitter_f", "twitter_h", "tumblr", "instagram", "hatena", "evernote"]
    rand_app = app_list.sample     

    @content = one_data_create(rand_app, "")     
    
    this_id =  @content[:id]
    time = Time.now
  
    Individual_log.create({
      :user_id => current_user.id,
      :data_id => this_id,
      :time => time,
    })
    
    haml :individual

  end

end


post "/individual" do

  @menu = Array.new
  @menu.push(["main", "d"])
  @menu.push(["settings", "c"])
  @menu.push(["logout", "c"])

  @relates_array = Array.new
  
  @content = one_data_create(params[:app], params[:data_id])
   
  this_id = @content[:id]
  time = Time.now
  
  Individual_log.create({
    :user_id => current_user.id,
    :data_id => this_id,
    :time => time,
  })
        
  haml :individual
end

get "/reject/:app" do

  reject(params[:app])
  
  redirect to ("/settings")

end

get "/reject/rss/:id" do

  Tags.where(:user_id => current_user.id, :app => "rss").delete
  Rss_user_relate.where(:user_id => current_user.id, :channel_id => params[:id]).delete
  
  redirect to ("/settings")
  
end

get "/:name/:page" do
#get "/:name" do

  if request.env["warden"].user.nil?
    redirect to ("/")
  else
    @menu = Array.new
    @menu.push(["main", "d"])
    @menu.push(["settings", "c"])
    @menu.push(["logout", "c"])

  
    @tagname = params[:name]
    page = params[:page].to_i
    #contents = Tags.select(:data_id, :app).filter(:tag => params[:name])
    contents = Tags.select(:data_id, :app).filter(:tag => @tagname).order_by(:id.desc)
  
    @paginated = contents.paginate(page, 4)
  
    @contents_array = Array.new 
  
    @paginated.each do |elem|
      
      this_data = one_data_create(elem.app, elem.data_id)
      @contents_array.push(data_hash)
          
    end
    
    time = Time.now.to_s
  
    Search_log.create({
      :user_id => current_user.id,
      :tag => @tagname,
      :time => time,
      :page => params[:page],
    })
    
    search_log = Search_log.where(:tag => @tagname, :time => time, :page => params[:page]).first
    
    @contents_array.each do |elem|
      this_id = elem[:id]
      Log_dataset.create({
        :log_id => search_log.log_id,
        :data_id => this_id,
      })          
  
    end 
    
    haml :tagsearch
  end
end
