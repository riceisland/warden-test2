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
require 'parallel'
require 'resque'
require 'resque_scheduler'
require 'yaml'
require 'redis'
require 'flickraw'

#require "sinatra/reloader" if development?

#evernote用
#require "../evernote_config.rb"

require "../model.rb"
load './job.rb'

require_relative '../lib/data.rb'
require_relative '../lib/oauth.rb'
require "../extract.rb"

load '../controller/login.rb'
load '../controller/ques.rb'
load '../controller/oauth.rb'

module Logref

	class WebApp < Sinatra::Base
	
		include Oauth
		
		set :public_folder, File.join(File.dirname(__FILE__) , %w{ .. public })
		enable :sessions
		#use Rack::Session::Cookie, :secret => Digest::SHA1.hexdigest(rand.to_s)
		enable :method_override
		
		Resque.redis = 'localhost:6379'
		Resque.schedule = YAML.load_file("../resque_schedule.yaml")
		
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
		
		before do
		  @conf = YAML.load_file("../config.yaml")
		
		  @title = "まとめてらんだむ"
		
		  Instagram.configure do |config|
		    config.client_id = @conf["instagram_config"]["key"]
		    config.client_secret = @conf["instagram_config"]["secret"]
		  end
		  
		  #instagram用
		  CALLBACK_URL = "http://localhost:4567/instagram_callback"
		  #CALLBACK_URL = "http://java.slis.tsukuba.ac.jp/log-ref/instagram_callback"
		  
		  FlickRaw.api_key = @conf["flickr_config"]["key"]
		  FlickRaw.shared_secret = @conf["flickr_config"]["secret"]
		  
		end
		
		use Login
		use Ques
		use Oauth_register
		
		# ログインしていないときは、ログインフォームを表示。
		# ログインしているときは、ログイン済ページを表示。
		get "/" do
		  
		  	@menu = Array.new
		  	@menu.push(["top", "pure-menu-selected"])
		  	@menu.push(["about", ""])
		  	
		  if request.env["warden"].user.nil?
		    @menu.push(["login", ""])
		    @menu.push(["register", ""])
		  else
		    @menu.push(["main", ""])
		    @menu.push(["settings", ""])
		    @menu.push(["logout", ""])
		  
		  end
		    #erb :login
		    haml :top
		  #else
		  #  redirect to ('/main')
		  #end
		end
		
		
		get "/settings" do
		  if request.env["warden"].user.nil?
		    redirect to ("/")
		  else
			@menu = Array.new
		    @menu.push(["top", ""])	
		  	@menu.push(["about", ""])
		    @menu.push(["main", ""])
		    @menu.push(["settings", "pure-menu-selected"])
		    @menu.push(["logout", ""])
		  
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
		    
		    flickr_oauth = Flickr_oauth.where(:uid => current_user.id).first
		    if flickr_oauth
		      @settings_array.push(["flickr", "/reject/flickr", "認証をやめる","b"])
		    else
		      @settings_array.push(["flickr", "/flickr_request_token", "認証する","e"])
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
		    
		    browser_bookmarks = Browser_bookmarks.where(:user_id => current_user.id).first
		    if browser_bookmarks
		      @browser_bookmarks = ""
		    
		    elsif  params[:bm]
		      @browser_bookmarks = ""
		    
		    else
		    end
		    
		    haml :"settings"
		  end
		end
		
		get "/data_refresh" do
		
		  Resque.enqueue(DataRefresh, current_user.id)
		  redirect to ("/settings")
		
		end
		
		post "/rss_register" do
		
		  url = params[:rss_url]
		  data_hash = Hash.new
		  
		  if url == ""
		    data_hash["status"] = "error"
		    data_json = JSON.generate(data_hash)  
		    return data_json
		    
		  else
		  
		  begin
		    feed = FeedNormalizer::FeedNormalizer.parse(open(url))
		    channel_title = feed.title.force_encoding("UTF-8")
		    rss_data = RssData::RssData.new(current_user.id)
		    
		    past_regist = Rss_channel.where(:link => url).first
		    #p past_regist
		
		    unless past_regist
		      Rss_channel.create({
		      	:link => url,
		      	:title => channel_title,
		      })
		    end
		
		    this_channel = Rss_channel.select(:channel_id).where(:link => url).first 
		    
		    feed.entries.reject{|x|x.title=~/^PR:/}.map{|e|
		     rss_data.rss_db_create(e, channel_id)
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
		  
		end
		
		get "/data_refresh" do
		
		  Resque.enqueue(DataRefresh, current_user.id)
		
		  redirect to ("/settings")
		  
		end  
		
		get '/main' do
		
		  if request.env["warden"].user.nil?
		    redirect to ("/")
		  else
		    @main = ""
		  
		    @menu = Array.new
		    @menu.push(["top", ""])
		  	@menu.push(["about", ""])
		    @menu.push(["main", "pure-menu-selected"])
		    @menu.push(["settings", ""])
		    @menu.push(["logout", ""])
		
		    @contents_array = Array.new
		    apps = Array.new
		
		    twitter_oauth = Twitter_oauth.where(:uid => current_user.id).first
		    if twitter_oauth
		      apps.push("twitter_f")
		      apps.push("twitter_h")
		      apps.push("twitter_m")
		      apps.push("twitter_u")
		      
		      
		    end
		    
		    tumblr_oauth = Tumblr_oauth.where(:uid => current_user.id).first
		    if tumblr_oauth
		     # apps.push("tumblr")
		    end
		  
		    instagram_oauth = Instagram_oauth.where(:uid => current_user.id).first
		    if instagram_oauth
		    #  apps.push("instagram")
		    end
		
		    flickr_oauth = Flickr_oauth.where(:uid => current_user.id).first
		    if flickr_oauth
		      apps.push("flickr")
		    
		      flickr_f = Flickr_favorites.where(:user_id => current_user.id).first
		      if flickr_f
		        apps.push("flickr_f")
		      end
		    end
		        
		    hatena_oauth = Hatena_oauth.where(:uid => current_user.id).first
		    if hatena_oauth
		      #apps.push("hatena")
		    end
		    
		    @evernote_oauth = Evernote_oauth.where(:uid => current_user.id).first
		    if @evernote_oauth
		      apps.push("evernote")
		    end
		
		    rss = Rss_user_relate.where(:user_id => current_user.id).first
		    if rss
		      apps.push("rss")
		    end
		    
		    browser_bookmarks = Browser_bookmarks.where(:user_id => current_user.id).first
		    
		    if browser_bookmarks
		      apps.push("browser_bookmarks")
		    end
		    
		    p apps
		    #logref_data = LogRef::LogRefData.new
		    
		    if apps.length < 5
		      
		      begin
		        
		        odd = 5 - apps.length
		        p odd
		      
		        app2 = ""
		        app2 = apps.sample(odd)
		        p app2
		        
		        app2.each do |elem|
		          apps.push(elem)
		        end
		        
		        p apps
		      
		      
		      end while apps.length < 5
		    
		    end
		       
		    
		    Parallel.each(apps, in_threads:9){|app|
		     
		      begin
		        data_hash = AllData.one_data_create(current_user.id,app, "")
		        #p data_hash 
		      rescue Twitter::Error::Unauthorized => error
			  
			    if error.to_s.index("Invalid or expired token")
		          reject("twitter")
			    end
			  
			  rescue Twitter::Error::BadRequest => error
			    
			    if error.to_s.index("Bad authentication data")
		          reject("twitter")
			    end	    
			  
			  rescue Twitter::Error::Forbidden => error
		
		      rescue NoMethodError => e
			    p e
			  #  retry
			
			  rescue Evernote::EDAM::Error::EDAMUserException => e
			 	#再認証が必要
		        if e.errorCode == 9
		          reject("evernote")            
		        end
		      
		      rescue => e
		      #もし認証が切れた場合は強制reject操作しておく
		        if e.message == "token_rejected"
		          reject("hatena")
		          
		        elsif e.message ==  "'flickr.photos.search' - Invalied API Key"
		          reject("flickr")
		        
		        elsif e.message ==  "'flickr.favorites.getList' - Invalied API Key"
		          reject("flickr")  
		              
		        end
		    
		      end
		      
		     # p data_hash
		      unless data_hash == ""
		        @contents_array.push(data_hash)
		      end
		          
		    }
		    
		    ids = ""
		    @contents_array.compact!
		    @contents_array.each do |elem|
		
		      if elem
		        
		        ids = ids + elem[:id].to_s + ","
		      end
		    end
		    
		    ids.chop
		    time = Time.now
		    
		    #p ids
		    
		    Main_log.create({
		      :user_id => current_user.id,
		      :dataset => ids,
		      :time => time,
		    })
		   
		   haml :main2
		 end
		end
		
		post "/tagedit" do
		
		  dataset = params[:data_id].split("-")
		
		  Alldata.tag_recreate(current_user.id,dataset[1], params[:tag_edit], dataset[0])
		  
		  if dataset[0] == "hatena"    
		
		    begin
		      /([0-9]+)$/ =~ id
		      eid = $1
		    
		    rescue
		      
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
		  end
		 
		  return AllData.tag_a_concat(current_user.id,dataset[1]) 
		end
		
		post "/comment" do
		
		  dataset = params[:data_id].split("-")
		
		  data = AllData.db_comment_create(current_user.id, dataset[0], dataset[1], params[:comment])
		  
		  data_json = JSON.generate(data)
		  
		  #p data_json  
		  
		  return data_json
		  
		end
		
		post "/refrection" do
		  count = params[:ref_count].to_i
		  count = count + 1
		  new_count = count.to_s
		  
		  dataset = params[:data_id].split("-")
		  id = dataset[1]
		  
		  case dataset[0]
		  
		  when "twitter_f"  
		    Twitter_favorites.filter(:id => id).update(:refrection => count)
		    
		  when "twitter_h" 
		    Tweets.filter(:id => id).update(:refrection => count)
		  
		  when "tumblr"  
		    Tumblr_posts.filter(:id => id).update(:refrection => count)    
		
		  when "instagram"  
		    Instagram_photos.filter(:id => id).update(:refrection => count)
		
		  when "flickr"  
		    Flickr_photos.filter(:id => id).update(:refrection => count)    
		
		  when "hatena"  
		    Hatena_bookmarks.filter(:id => id).update(:refrection => count)
		    
		  when "evernote"  
		    Evernote_notes.filter(:id => id).update(:refrection => count) 
		  
		  when "rss"
		    Rss_user_relate.filter(:id => id).update(:refrection => count)
		
		  when "browser_bookmarks"
		    Browser_bookmarks.filter(:id => id).update(:refrection => count)  
		              
		  else
		  end
		
		  time = Time.now.to_s
		  
		  Reflection_log.create({
		    :user_id => current_user.id,
		    :id => id,
		    :time => time,
		  })  
		  
		  #p new_count
		  return new_count
		end
		
		#ふわっと更新時にajaxで呼び出されるページ
		get "/individual" do
		
		  if request.env["warden"].user.nil?
		
		    str = "logout"
		   
		  else
		   
		    begin
		      app_list = ["twitter_f", "twitter_h", "tumblr", "instagram", "hatena", "evernote", "flickr", "flickr_f", "twitter_u", "twitter_m"]
		      rand_app = app_list.sample     
		
		      @content = AllData.one_data_create(current_user.id,rand_app, "")     
		      p @content
		      
		      if @content == ""
		        raise "NoContent"
		      end
		    
		    rescue
		      retry
		      
		    end
		    
		    str = AllData.data_to_html(@content)
		   
		    this_id = @content[:id]
		    time = Time.now
		  
		    Individual_log.create({
		      :user_id => current_user.id,
		      :id => this_id,
		      :time => time,
		    })
		
		  end
		  
		  return str
		
		end
		
		
		post "/individual" do
		
		  @menu = Array.new
		  @menu.push(["top", ""]) 
		  @menu.push(["about", ""])
		  @menu.push(["main", "pure-menu-selected"])
		  @menu.push(["settings", ""])
		  @menu.push(["logout", ""])
		
		  @relates_array = Array.new
		  
		  id = params[:data_id].split("-")
		  #p id[1]
		  @content = AllData.one_data_create(current_user.id,params[:app], id[1])
		   
		  this_id = @content[:id]
		  time = Time.now
		  
		  Individual_log.create({
		    :user_id => current_user.id,
		    :id => this_id,
		    :time => time,
		  })
		        
		  haml :individual
		end
		
		get "/reject/:app" do
		
		  AllData.reject(current_user.id,params[:app])
		  redirect "/settings"
		
		end
		
		get "/reject/rss/:id" do
		
		  Tags.where(:user_id => current_user.id, :app => "rss").delete
		  Rss_user_relate.where(:user_id => current_user.id, :channel_id => params[:id]).delete
		  
		  redirect to ("/settings")
		  
		end
		
		get "/tagsearch" do
		#get "/:name" do
		
		  if request.env["warden"].user.nil?
		    redirect to ("/")
		  else
		    @menu = Array.new
		    @menu.push(["top", ""])
		  	@menu.push(["about", ""])
		    @menu.push(["main", "pure-menu-selected"])
		    @menu.push(["settings", ""])
		    @menu.push(["logout", ""])
		
		  
		    @tagname = params[:tagname]
		    page = params[:page].to_i
		    #contents = Tags.select(:data_id, :app).filter(:tag => params[:name])
		    contents = Tags.select(:id, :data_id, :app).filter(:tag => @tagname).order_by(:id.desc)
		  
		    @paginated = contents.paginate(page, 4)
		  
		    @contents_array = Array.new 
		  
		    @paginated.each do |elem|
		      
		      data_hash = AllData.one_data_create(current_user.id, elem.app, elem.data_id)
		      @contents_array.push(data_hash)
		          
		    end
		    
		    time = Time.now.to_s
		    
		    ids = ""
		    @contents_array.each do |elem|
		      if elem
		        ids = elem[:id].to_s + ","
		      end
		    end
		    
		    ids.chop
		  
		    Search_log.create({
		      :user_id => current_user.id,
		      :tag => @tagname,
		      :time => time,
		      :page => params[:page],
		      :dataset => ids,
		    })
		    
		    haml :tagsearch
		  end
		end
		
		post "/remove" do
		 
		  id = params[:data_id].split("-")
		  p id[1]
		  
		  case params[:app]
		    when "twitter_h"
		      Tweets.where(:user_id => current_user.id, :id => id).delete
		      
			when "tumblr"
			  Tumblr_posts.where(:user_id => current_user.id, :id => id).delete
		      
			when "instagram"
			  Instagram_photos.where(:user_id => current_user.id, :id => id).delete
		    
		    when "flickr"
			  Flickr_photos.where(:user_id => current_user.id, :id => id).delete
			   
			when "hatena"
			  Hatena_bookmarks.where(:user_id => current_user.id, :id => id).delete
			  
			when "evernote"
			  Evernote_notes.where(:user_id => current_user.id, :id => id).delete
			  
			when "browser_bookmarks"
			  Browser_bookmakrs.where(:user_id => current_user.id, :id => id).delete
		
			else
		  end  
		
		  Tags.where(:user_id => current_user.id, :data_id => id).delete
		
		  return "ok"
		
		end
		
		get "/about" do
		  @menu = Array.new
		  @menu.push(["top", ""])
		  @menu.push(["about", "pure-menu-selected"])
		  
		  if request.env["warden"].user.nil?
		    @menu.push(["login", ""])
		    @menu.push(["register", ""])
		  else
		    @menu.push(["main", ""])
		    @menu.push(["settings", ""])
		    @menu.push(["logout", ""])
		  end
		
		  haml :about
		
		end

		put "/upload" do
		  
		  if params[:file]
		    f = params[:file][:tempfile]
		    p f
		    file = f.read
		    file.force_encoding("UTF-8")
		    
		        
		    Resque.enqueue(BookmarkDataCreate, current_user.id, file)
		    
		    
		    redirect to ("/settings?bm=create")
		
		  end 
		end
		
		get '/recruit' do
		
		  haml :recruit, :layout => false
		
		end
		
		post '/recruit' do
		  
		  time = Time.now.to_s
		  
		  Recruit.create({
		    :username => params[:username],
		    :mail => params[:mail],
		    :question => params[:question],
		    :check => 0,
		    :time => time,
		  })
		
		
		  p "ご応募ありがとうございます。後ほど実験担当者よりメールにて連絡致します。"
		
		end
		
		get '/top' do
		
		  redirect ("/")
		 
		end
		
		not_found do
		
		  @menu = Array.new
		  @menu.push(["top", ""])
		  @menu.push(["about", ""])
		  
		  if request.env["warden"].user.nil?
		    @menu.push(["login", ""])
		    @menu.push(["register", ""])
		  else
		    @menu.push(["main", ""])
		    @menu.push(["settings", ""])
		    @menu.push(["logout", ""])
		  end
		  
		  haml :notfound
		
		end
		
		error do
		
		  haml :error, :layout => false
		
		end


	end
end
		
Logref::WebApp.run!
