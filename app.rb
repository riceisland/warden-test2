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
require 'net/http'
require 'instagram'
require 'open-uri'
require 'nokogiri'
require 'will_paginate'
require 'will_paginate/sequel'
require "sinatra/reloader" if development?

#evernote用
require "./evernote_config"

# Sinatra のセッションを有効にする
enable :sessions
set :public_folder, File.join(File.dirname(__FILE__) , %w{ . public })


#sequel使えるようにする
Sequel::Model.plugin(:schema)
Sequel.extension :pagination
Sequel.connect("sqlite://user.db")

class User < Sequel::Model
  unless table_exists?
    set_schema do
	  primary_key :id
	  varchar :name
	  varchar :password
	end
	create_table
  end
  
  #認証メソッド
  def self.authenticate(name, hexpass)    
    #p hexpass
    user = self.first(name: name)  
    user if user && user.password == hexpass
  end
  
end

class Twitter_oauth < Sequel::Model
  unless table_exists?
    set_schema do
      varchar :uid
      varchar :twitter_access_token
      varchar :twitter_access_token_secret
    end
    create_table
  end
end

class Tweets < Sequel::Model
  unless table_exists?
    set_schema do
	  primary_key :id
	  integer :user_id
	  integer :data_id
	  integer :refrection
	end
	create_table
  end
end

class Tumblr_oauth < Sequel::Model
  unless table_exists?
    set_schema do
      varchar :uid
      varchar :tumblr_access_token
      varchar :tumblr_access_token_secret
    end
    create_table
  end
end

class Tumblr_posts < Sequel::Model
  unless table_exists?
    set_schema do
	  primary_key :id
	  integer :user_id
	  integer :data_id
	  integer :refrection
	end
	create_table
  end
end

class Instagram_oauth < Sequel::Model
  unless table_exists?
    set_schema do
      varchar :uid
      varchar :instagram_access_token
    end
    create_table
  end
end

class Instagram_photos < Sequel::Model
  unless table_exists?
    set_schema do
      primary_key :id
      integer :user_id
      varchar :data_id
      integer :refrection
    end
    create_table
  end
end

class Hatena_oauth < Sequel::Model
  unless table_exists?
    set_schema do
      varchar :uid
      varchar :hatena_access_token
      varchar :hatena_access_token_secret
    end
    create_table
  end
end

class Hatena_bookmarks < Sequel::Model
  unless table_exists?
    set_schema do
      primary_key :id
      integer :user_id
      varchar :name
      varchar :data_id
      varchar :title
      varchar :url
      varchar :issued
      varchar :comment
      integer :refrection
    end
    create_table
  end
end

class Evernote_oauth < Sequel::Model
  unless table_exists?
    set_schema do
      varchar :uid
      varchar :evernote_access_token
      varchar :evernote_shard_id
    end
    create_table
  end
end

class Evernote_notes < Sequel::Model
  unless table_exists?
    set_schema do
	  primary_key :id
	  integer :user_id
	  varchar :data_id
	  varchar :refrection
	end
	create_table
  end
end

class Tags < Sequel::Model
  unless table_exists?
    set_schema do
      primary_key :id
	  integer :user_id
	  varchar :data_id
	  varchar :tag
	  varchar :app
	end
	create_table
  end
end      

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

#twitter,tumblr,instagram key,secret
configure do

  use Rack::Session::Cookie, :secret => Digest::SHA1.hexdigest(rand.to_s)
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
#	config.oauth_token = session[:twitter_access_token]
    config.oauth_token = token
#	config.oauth_token_secret = session[:twitter_access_token_secret]
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

#def configure_instagram_token(token, secret)
  Instagram.configure do |config|
    config.client_id = INSTAGRAM_KEY
    config.client_secret = INSTAGRAM_SECRET
  end
#end

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
  @prefix = "/mat_rnd"

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
    when "twitter"
      ids = Tweets.select(:data_id).filter(:user_id => current_user.id)
    
    when "tumblr"
      ids = Tumblr_posts.select(:data_id).filter(:user_id => current_user.id)
    
    when "instagram"
      ids = Instagram_photos.select(:data_id).filter(:user_id => current_user.id)
    
    when "hatena"
      ids = Hatena_bookmarks.select(:data_id).filter(:user_id => current_user.id)    
      
    when "evernote"
      ids = Evernote_notes.select(:data_id).filter(:user_id => current_user.id)    
    else
  end
  		
  ids.each do |id|
	content_ids.push(id.data_id)
  end
	
  rand_id = content_ids.sample
  #rand_id = "276189947369775105"
  
  return rand_id

end

def twitter_data_create(id)
  
  ref_count = ref_counter("twitter", id)
	 
  @twitter.favorites(:count=> 1, :max_id => id).each do |fav|
    
    @twitter_img_url = fav.user.profile_image_url 
    @twitter_user_name = fav.user.name
    @twitter_screen_name = fav.user.screen_name
    @twitter_text = fav.text
    @twitter_time = fav.created_at
	 # @twitter_long_url = 'https://twitter.com/_/status/' + @rand_fav_id.to_s
	  #@short_url = shorten(@long_url)
  end
    
  twitter_tag_concat = tag_concat(id)
  twitter_tag_array = tag_array(id)
    
  data_hash = {:app => "twitter", :twitter_img_url => @twitter_img_url, :twitter_user_name => @twitter_user_name, :twitter_screen_name => @twitter_screen_name, :twitter_text => @twitter_text, :twitter_time => @twitter_time, :twitter_tag_concat => twitter_tag_concat, :twitter_tag_array => twitter_tag_array, :rand_fav_id => id, :twitter_ref_count => ref_count }
    
  return data_hash

end

def tumblr_data_create(id)

  ref_count = ref_counter("tumblr", id)
  #p ref_count
        
  blogurl = @tumblr.info.user.blogs[0].url
  blogurl.gsub!('http://', '')
    
  post = @tumblr.posts(blogurl, {:id => id}).posts[0]
    
  tumblr_tag_array = tag_array(id)
  tumblr_tag_concat = tag_concat(id)
    
  type = post.type
  tags = post.tag
  p tags
    
  content = {:app => "tumblr", :rand_post_id => id, :type => type, :tumblr_tag_concat => tumblr_tag_concat, :tumblr_tag_array => tumblr_tag_array, :tumblr_ref_count => ref_count}
    
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
	  
  photo = @instagram.media_item(id)
  instagram_img_url = photo.images.low_resolution.url
	
  if photo.caption
    instagram_tags = photo.tags #array  
    instagram_time = photo.caption.created_time
    instagram_text = photo.caption.text
  else
    instagram_tags = nil
    instagram_time = nil
    instagram_text = nil
  end
    
  instagram_tag_array = tag_array(id)
  instagram_tag_concat = tag_concat(id)

  data_hash = {:app => "instagram", :instagram_img_url => instagram_img_url, :instagram_tags => instagram_tags, :instagram_time => :instagram_time, :instagram_text => instagram_text, :instagram_tag_concat => instagram_tag_concat, :instagram_tag_array => instagram_tag_array, :rand_photo_id => id, :instagram_ref_count => ref_count }
  
  return data_hash

end

def hatena_data_create(id)

  ref_count = ref_counter("hatena", id)
    
  bookmark = Hatena_bookmarks.filter(:data_id => id)
    
  bookmark.each do |elem|
    @hatena_title = elem.title
    @hatena_url = elem.url
    @hatena_issued = elem.issued
  end 
    
  hatena_tag_array = tag_array(id)
  hatena_tag_concat = tag_concat(id)
    
  data_hash = {:app => "hatena", :hatena_title => @hatena_title, :hatena_url => @hatena_url, :hatena_issued => @hatena_issued, :hatena_tag_concat => hatena_tag_concat, :hatena_tag_array => hatena_tag_array, :rand_bkm_id => id, :hatena_ref_count => ref_count }
  
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
	   
  evernote_tag_array = tag_array(id)
  evernote_tag_concat = tag_concat(id)
	  
  data_hash = {:app => "evernote", :note_title => @note_title, :content => @content, :snippet => @snippet, :link => @link, :evernote_tag_concat => evernote_tag_concat, :evernote_tag_array => evernote_tag_array, :rand_note_id => id, :evernote_ref_count => ref_count }
  
  return data_hash

end

def ref_counter(app, id)

  case app
    when "twitter"
      ref_sql = Tweets.select(:refrection).filter(:data_id => id)
    
    when "tumblr"
      ref_sql = Tumblr_posts.select(:refrection).filter(:data_id => id)
    
    when "instagram"
      ref_sql = Instagram_photos.select(:refrection).filter(:data_id => id)
    
    when "hatena"
      ref_sql = Hatena_bookmarks.select(:refrection).filter(:data_id => id)
    
    when "evernote"
      ref_sql = Evernote_notes.select(:refrection).filter(:data_id => id)
    else
  end
  
  ref_sql.each do |ref|
	ref_count = ref.refrection
	return ref_count
  end 
  
end


def tag_array(data_id)
  tags = Tags.select(:tag).filter(:user_id => current_user.id, :data_id => data_id) 
  #tag_concat = ""
  tag_concat = Array.new
  tags.each do |tag|
    #tag_concat = tag_concat + tag.tag + ","
    tag_concat.push(tag.tag)
  end
  #tag_concat.chop!
  return tag_concat
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
   Tags.create({
     :user_id => current_user.id,
     :data_id => id,
     :tag => elem,
     :app => app,
   })
   end
end
    
#passtest = OpenSSL::Digest::SHA1.hexdigest("secret")
#User.create(name: 'aaa', password: passtest)

# 認証方式を登録。
# 実際に開発するときは、データベースに保存しているユーザー情報と
# 照合するなり、OAuth 使うなりするはず。
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
    #if params["name"] == "test" && params["password"] == "test"
      # ユーザー名とパスワードが正しければログイン成功
    #  user = {
    #    :name => params["name"],
    #    :password => params["password"]
    #  }
    #  success!(user)
    #else
      # ユーザー名とパスワードのどちらかでも間違っていたら
      # ログイン失敗
    #  fail!("Could not log in")
    #end
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
  # 今回は単なる Hash だけど、実際の開発ではデータベースから取得するはず
  #Warden::Manager.serialize_from_session do |id|
  #  { :name => id, :password => "test" }
  #end

  Warden::Manager.serialize_from_session{|id| User[id] }
 
  # ユーザー情報からセッションに格納する ID を取り出す
  #Warden::Manager.serialize_into_session do |user|
  #  user[:name]
  #end
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
	#@menu = Array.new
    #@menu.push(["main", "c"])
    #@menu.push(["settings", "c"])
    #@menu.push(["logout", "c"])
    #erb :success_login
    #haml :success_login
    redirect '/main'
  end
end

# 認証を実行する。
# 成功すれば設定ページに移動。
post "/login" do
  request.env["warden"].authenticate!
  redirect "/settings"
end

#get-login（URL直打ちパターン）
get "/login" do  
  if request.env["warden"].user.nil?
  
    @menu = Array.new
    @menu.push(["login", "d"])
    @menu.push(["register", "c"])
    #erb :login
    haml :login
  else
    
	redirect "/main"
    #erb :success_login
    #haml :success_login
  end
end


# 認証に失敗したとき呼ばれるルート。
# ログイン失敗ページを表示してみる。
#redirectで吹っ飛ばす推奨
post "/unauthenticated" do
  
  @menu = Array.new
  @menu.push(["login", "c"])
  @menu.push(["register", "d"])
  #erb :fail_login
  haml :fail_login
end

# ログアウトする。
# ログアウト後はトップページに移動。
get "/logout" do
  request.env["warden"].logout
  redirect "/"
end

get "/register" do
  if request.env["warden"].user.nil?
    @menu = Array.new
    @menu.push(["login", "c"])
    @menu.push(["register", "d"])
    #erb :register
    haml :register
  else
    redirect "/main"
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
      redirect "/settings"
    else
      redirect "/register"
    end
  else
    redirect "/register"
  end
end

get "/settings" do
  if request.env["warden"].user.nil?
    redirect "/"
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
    
    session[:test] = "test"
    p session.to_hash
    #p @settings_array
    
    haml :"settings"
  end
end

get "/data_refresh" do

#twitter
  
  favs = Tweets.select(:data_id).filter(:user_id => current_user.id).first
  
  if favs
    twitter_oauth = Twitter_oauth.where(:uid => current_user.id).first
    
    configure_twitter_token(twitter_oauth.twitter_access_token, twitter_oauth.twitter_access_token_secret)
    twitter = Twitter::Client.new
    
    twitter.favorites(:count => 100).each do |twit|
 
  	  past_fav = Tweets.select(:id).filter(:user_id => current_user.id, :data_id => twit.id)

      if past_fav.empty?
        Tweets.create({
	      :user_id => current_user.id,
		  :data_id => twit.id,
		  :refrection => 0,
	    })
	  else
	    break
	  end
	        
    end  #--each do
    
  end  #-- if favs
  
#tumblr
  
  posts = Tumblr_posts.select(:data_id).filter(:user_id => current_user.id).first
  
  if posts
    tumblr_oauth = Tumblr_oauth.where(:uid => current_user.id).first

    configure_tumblr_token(tumblr_oauth.tumblr_access_token, tumblr_oauth.tumblr_access_token_secret)
    tumblr = Tumblife.client
    
    info = tumblr.info
    blogurl = info.user.blogs[0].url
    blogurl.gsub!('http://', '')
    
    offset = 0
    limit = 20
    
    catch(:tumblr_exit){
      begin
        res = tumblr.posts(blogurl, {:offset => offset, :limit => limit})

        res.posts.each do |post|
      
          past_post = Tumblr_posts.select(:id).filter(:user_id => current_user.id, :data_id => post.id)
      
          if past_post.empty?
        
            Tumblr_posts.create({
              :user_id => current_user.id,
              :data_id => post.id,
              :refrection => 0,
            })
            
            post.tags.each do |tag|
            
              Tags.create({
                :user_id => current_user.id,
                :data_id => post.id,
                :tag => tag,
                :app => "tumblr",
              })
              
            end
            
          else
            throw :tumblr_exit
          end
        
        end
        offset += limit      
      end while offset < res.total_posts
    }
  
  end
  
#instagram

  photos = Instagram_photos.select(:data_id).filter(:user_id => current_user.id).first
  
  if photos
    instagram_oauth = Instagram_oauth.where(:uid => current_user.id).first
    
    instagram = Instagram.client(:access_token => instagram_oauth.instagram_access_token)
    
    instagram.user_recent_media.each do |photo|
    
      past_photo = Instagram_photos.select(:id).filter(:user_id => current_user.id, :data_id => photo.id)
      
      if past_photo.empty?
        Instagram_photos.create({
          :user_id => current_user.id,
          :data_id => photo.id,
          :refrection => 0,
        })
        
        if photo.tags #array
        
          photo.tags.each do |tag|            
            Tags.create({
              :user_id => current_user.id,
              :data_id => photo.id,
              :tag => tag,
              :app => "instagram",
            })              
          end      
      
        end
        
        
      else
        break
      end
    end
    
  end

#evernote

  notes = Evernote_notes.select(:data_id).filter(:user_id => current_user.id).first
  
  if notes
    evernote_oauth = Evernote_oauth.where(:uid => current_user.id).first
    
    noteStoreUrl = NOTESTORE_URL_BASE + evernote_oauth.evernote_shard_id
    noteStoreTransport = Thrift::HTTPClientTransport.new(noteStoreUrl)
    noteStoreProtocol = Thrift::BinaryProtocol.new(noteStoreTransport)
    noteStore = Evernote::EDAM::NoteStore::NoteStore::Client.new(noteStoreProtocol)
    
    notebooks = noteStore.listNotebooks(evernote_oauth.evernote_access_token)
      
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
  
    catch(:evernote_exit){
      begin      
      res = noteStore.findNotesMetadata(evernote_oauth.evernote_access_token, filter, offset, 10, spec)
      
      i = res.notes.length
      while i > 0 
      
        i = i - 1      
        past_note = Evernote_notes.select(:id).filter(:user_id => current_user.id, :data_id => res.notes[i].guid)

      
        if past_note.empty?
        
          Evernote_notes.create({
            :user_id => current_user.id,
            :data_id => res.notes[i].guid,
            :refrection => 0,
          })
       
          evernote_tags = res.notes[i].tagGuids
          if evernote_tags
            evernote_tags.each do |tag_id|
              tag_resource = noteStore.getTag(evernote_oauth.evernote_access_token, tag_id)
              tag = tag_resource.name.force_encoding("UTF-8")
              Tags.create({
                :user_id => current_user.id,
                :data_id => res.notes[i].guid,
                :tag => tag,
              })  
            end  #-- evernote_tags.each
          end #--if evernote_tags
          
        else
          throw :evernote_exit
        end #-- if past_note.empty?          
       
      end #-- while
    
      offset = offset + pageSize
    
    end while res.totalNotes > offset
    
    } #-- catch
  
  end

#hatena

  bookmarks = Hatena_bookmarks.select(:data_id).filter(:user_id => current_user.id).first
  
  p bookmarks
  
  if bookmarks
  
    hatena_oauth = Hatena_oauth.where(:uid => current_user.id).first
  
    hatena = OAuth::AccessToken.new(
      hatena_oauth_consumer,
      hatena_oauth.hatena_access_token,
      hatena_oauth.hatena_access_token_secret)
    
    
    request_url = 'http://b.hatena.ne.jp/atom/feed?of=0' 
  
    catch(:hatena_exit){  
      while true
        response = hatena.request(:get, request_url)
  
        xml_doc = Nokogiri::XML(response.body)
        xml_doc.css("entry").each do |elem|
          entry_doc = Nokogiri::XML(elem.to_html)
          id = entry_doc.css("id")[0].content
          title = entry_doc.css("title")[0].content
          issued = entry_doc.css("issued")[0].content
          name = entry_doc.css("name")[0].content
          comment = entry_doc.css("summary")[0].content
          url = entry_doc.xpath("//*[@rel='related']")[0].attribute("href").value 
        
          past_bookmark = Hatena_bookmarks.select(:id).filter(:user_id => current_user.id, :id => id)
        
          if past_bookmark.empty?
         
            entry_doc.xpath("//dc:subject", "dc" => 'http://purl.org/dc/elements/1.1/').each do |elem|
              Tags.create({
                :user_id => current_user.id,
                :data_id => id,
                :tag => elem.content,
              })
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
  end
    
#----setting refresh end  --------#  
  
  redirect "/settings"
  
end  

#twitter OAuth認証
get '/twitter_request_token' do
  #callback_url = "#{base_url}/access_token"
  callback_url = "#{base_url}/oauth/twitter/callback"
  request_token = twitter_oauth_consumer.get_request_token(:oauth_callback => callback_url)
  #p request_token
  session[:twitter_request_token] = request_token.token
  session[:twitter_request_token_secret] = request_token.secret
  p session[:twitter_request_token]
  redirect request_token.authorize_url
end

get '/oauth/twitter/callback' do
  #p session.to_hash
  request_token = OAuth::RequestToken.new(
    twitter_oauth_consumer, session[:twitter_request_token], session[:twitter_request_token_secret])
  #p request_token
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
  
  redirect '/twitter_set'
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

    #Tweets register
  
    configure_twitter_token(session[:twitter_access_token], session[:twitter_access_token_secret])
    @twitter = Twitter::Client.new
  
    @total_fav = @twitter.verify_credentials.favorites_count
    
    if @total_fav == 0
      session[:nofav] = "nofav"
      #redirect '/nofavorite'
    elsif @total_fav < 101
      @twitter.favorites(:count => @total_fav).each do |twit|
        Tweets.create({
          :user_id => current_user.id,
          :data_id => twit.id,
          :refrection => 0,
	    })
      end    
    else
    #ここをいじれば全件とれるかもしれない（evernoteを参考に）
      @twitter.favorites(:count => 100).each do |twit|
        Tweets.create({
	      :user_id => current_user.id,
          :data_id => twit.id,
          :refrection => 0,
	    })
      end
    end #-- if total_fav
  end
  
  redirect "/settings" 
end

get '/tumblr_request_token' do
  @consumer = tumblr_oauth_consumer
  request_token = @consumer.get_request_token(
    :oauth_callback => 'http://127.0.0.1:4567/t_callback')
   #p @consumer
  session[:tumblr_request_token] = request_token.token
  session[:tumblr_request_token_secret] = request_token.secret
  p session.to_hash
  #p session[:tumblr_request_token]
  redirect request_token.authorize_url
end

get '/t_callback' do
  #session.clear
  #p session.to_hash
  #p session.session_id
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
   redirect '/tumblr_set'

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
    
    configure_tumblr_token(session[:tumblr_access_token], session[:tumblr_access_token_secret])
    
    session.delete(:tumblr_access_token)
    session.delete(:tumblr_access_token_secret)
    
    
    @tumblr = Tumblife.client
    
    info = @tumblr.info
    blogurl = info.user.blogs[0].url
    blogurl.gsub!('http://', '')
    
    offset = 0
    limit = 20
    
    begin
      res = @tumblr.posts(blogurl, {:offset => offset, :limit => limit})
      #p res.total_posts
      #p offset
      res.posts.each do |post|
        Tumblr_posts.create({
          :user_id => current_user.id,
          :data_id => post.id,
          :refrection => 0,
        })
        
        post.tags.each do |tag|
            
          Tags.create({
            :user_id => current_user.id,
            :data_id => post.id,
            :tag => tag,
            :app => "tumblr",
          })
              
        end
      
      end
      offset += limit      
    end while offset < res.total_posts
    
  end 
  redirect "/settings" 
end

get "/instagram_request_token" do
  redirect Instagram.authorize_url(:redirect_uri => CALLBACK_URL)
end

get "/instagram_callback" do
  response = Instagram.get_access_token(params[:code], :redirect_uri => CALLBACK_URL)
  session[:instagram_access_token] = response.access_token
  redirect "/instagram_set"
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
    
    @instagram = Instagram.client(:access_token => session[:instagram_access_token])
    
    @instagram.user_recent_media.each do |photo|
      Instagram_photos.create({
        :user_id => current_user.id,
        :data_id => photo.id,
        :refrection => 0,
      })
      
      if photo.tags #array
        
        photo.tags.each do |tag|            
          Tags.create({
            :user_id => current_user.id,
            :data_id => photo.id,
            :tag => tag,
            :app => "instagram",
          })              
        end      
      
      end
        
      
    end
    
  end
   
  redirect "/settings" 
end

get "/hatena_request_token" do
  request_token = hatena_oauth_consumer.get_request_token(
    { :oauth_callback => 'http://localhost:4567/hatena_callback' },
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

  session[:hatena_request_token] = nil
  session[:hatena_request_token_secret] = nil

  # アクセストークンをセッションに記録しておく
  session[:hatena_access_token] = access_token.token
  session[:hatena_access_token_secret] = access_token.secret

  redirect "/hatena_set"
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
    
    @hatena = OAuth::AccessToken.new(
      hatena_oauth_consumer,
      session[:hatena_access_token],
      session[:hatena_access_token_secret])
   
   
   request_url = 'http://b.hatena.ne.jp/atom/feed?of=0' 
   
   
   catch(:hatena_exit){
     while true
       response = @hatena.request(:get, request_url)
  
       xml_doc = Nokogiri::XML(response.body)
       xml_doc.css("entry").each do |elem|
         entry_doc = Nokogiri::XML(elem.to_html)
         id = entry_doc.css("id")[0].content
         title = entry_doc.css("title")[0].content
         issued = entry_doc.css("issued")[0].content
         name = entry_doc.css("name")[0].content
         comment = entry_doc.css("summary")[0].content
         url = entry_doc.xpath("//*[@rel='related']")[0].attribute("href").value
       
         entry_doc.xpath("//dc:subject", "dc" => 'http://purl.org/dc/elements/1.1/').each do |elem|
           Tags.create({
             :user_id => current_user.id,
             :data_id => id,
             :tag => elem.content,
           })
         end

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
       end
       
       rel_next = xml_doc.xpath("//*[@rel='next']")[0]
          
       if rel_next
         request_url = xml_doc.xpath("//*[@rel='next']")[0].attribute("href").value
       else
         #request_url = ""
         #break
         throw :hatena_exit
       end
       
     end
   }
   
  end
  redirect "/settings"
end

get "/evernote_request_token" do
  callback_url =  "http://localhost:4567/evernote_callback"
  
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
      redirect '/evernote_set'
      
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
    
    # Construct the URL used to access the user's account
    noteStoreUrl = NOTESTORE_URL_BASE + session[:shard_id]
    noteStoreTransport = Thrift::HTTPClientTransport.new(noteStoreUrl)
    noteStoreProtocol = Thrift::BinaryProtocol.new(noteStoreTransport)
    noteStore = Evernote::EDAM::NoteStore::NoteStore::Client.new(noteStoreProtocol)
   
    notebooks = noteStore.listNotebooks(session[:evernote_access_token].token)
      
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
      res = noteStore.findNotesMetadata(session[:evernote_access_token].token, filter, offset, 10, spec)
      res.notes.each do |note|
        Evernote_notes.create({
          :user_id => current_user.id,
          :data_id => note.guid,
          :refrection => 0,
       })
       
       evernote_tags = note.tagGuids
       if evernote_tags
         evernote_tags.each do |tag_id|
           tag_resource = noteStore.getTag(session[:evernote_access_token].token, tag_id)
           tag = tag_resource.name.force_encoding("UTF-8")
           Tags.create({
             :user_id => current_user.id,
             :data_id => note.guid,
             :tag => tag,
           })  
         end
       end
            
      end
      offset = offset + pageSize
    end while res.totalNotes > offset

  
  end
  redirect "/settings"  
end

get '/main' do

  if request.env["warden"].user.nil?
    redirect "/"
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
    configure_twitter_token(twitter_oauth.twitter_access_token, twitter_oauth.twitter_access_token_secret)
    @twitter = Twitter::Client.new
    
    rand_fav_id = rand_id_sample("twitter")
	data_hash = twitter_data_create(rand_fav_id)
    @contents_array.push(data_hash)
    
	rescue
	
	end
	
  else
	@twitter = nil
  end
  
#tumblr--------------

  tumblr_oauth = Tumblr_oauth.where(:uid => current_user.id).first
  
  if tumblr_oauth
    configure_tumblr_token(tumblr_oauth.tumblr_access_token, tumblr_oauth.tumblr_access_token_secret)
    @tumblr = Tumblife.client
    
    rand_post_id = rand_id_sample("tumblr")
    data_hash = tumblr_data_create(rand_post_id)
    @contents_array.push(data_hash)
    
  else
	@tumblr = nil
  end

#instagram--------------  
  instagram_oauth = Instagram_oauth.where(:uid => current_user.id).first
  
  if instagram_oauth
   @instagram = Instagram.client(:access_token => instagram_oauth.instagram_access_token)
    
    rand_photo_id = rand_id_sample("instagram")	
	data_hash = instagram_data_create(rand_photo_id)
    @contents_array.push(data_hash)
    
  else
	@instagram = nil
  end

#hatena--------------  
  hatena_oauth = Hatena_oauth.where(:uid => current_user.id).first
  
  if hatena_oauth
    access_token = OAuth::AccessToken.new(
      hatena_oauth_consumer,
      hatena_oauth.hatena_access_token,
      hatena_oauth.hatena_access_token_secret)
      
    rand_bkm_id = rand_id_sample("hatena")
    data_hash = hatena_data_create(rand_bkm_id)
    @contents_array.push(data_hash)
  
  else
    @hatena = nil 
  end

#evernote--------------
  @evernote_oauth = Evernote_oauth.where(:uid => current_user.id).first

  if @evernote_oauth
    begin
      rand_note_id = rand_id_sample("evernote")
	  p rand_note_id
      data_hash = evernote_data_create(rand_note_id)
      @contents_array.push(data_hash)
	  
	rescue NoMethodError => e
	  p e
	  retry
	
	rescue Evernote::EDAM::Error::EDAMUserException => e
		#再認証が必要
		if e.errorCode == 9
		  Evernote_oauth.where(:uid => current_user.id).delete
		  @evernote = nil 
		end

    end
 
  else
     @evernote = nil   
  end  
 
 haml :main2
 end
end

post "/tagedit" do
 id = params[:data_id]
 if params[:twitter_tag_edit] 
   tags = params[:twitter_tag_edit]
   app = "twitter"
   tag_recreate(id, tags, app)
 
 elsif params[:tumblr_tag_edit] 
   tags = params[:tumblr_tag_edit]
   app = "tumblr"
   tag_recreate(id, tags, app)
   
 elsif params[:instagram_tag_edit] 
   tags = params[:instagram_tag_edit]
   app = "instagram"
   tag_recreate(id, tags, app)
   
 elsif params[:evernote_tag_edit] 
   tags = params[:evernote_tag_edit]
   app = "evernote"
   tag_recreate(id, tags, app)
 
 #本家のタグを合わせて更新するため分けてある
 else params[:hatena_tag_edit]
   tags = params[:hatena_tag_edit]
   app = "hatena"
   tag_recreate(id, tags, app)
    
    begin
      /([0-9]+)$/ =~ id
      eid = $1
    
    rescue
    
    #else
      
      #uri = URI.parse("http://localhost:4567")
      edituri = "http://b.hatena.ne.jp/atom/edit/" + $1
      #uri = URI.parse(edituri)
      
      #p uri.host
      #p uri.port
      #p edituri
      #p uri.path
      
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
 p tag_a_concat(id) 
end

post "/refrection" do
  count = params[:ref_count].to_i
  count = count + 1
  new_count = count.to_s
  
  if params[:twitter_data_id]
    id = params[:twitter_data_id]   
    Tweets.filter(:twit_id => id).update(:refrection => count)
  
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
              
  else
  end
  p new_count
end

#getで来られたときはとりあえずランダムで対応
get "/individual" do

  if request.env["warden"].user.nil?
    redirect "/"
  else
  
  	@menu = Array.new
    @menu.push(["main", "c"])
    @menu.push(["settings", "c"])
    @menu.push(["logout", "c"])
  
    "Hello get"
  end

end


post "/individual" do

  @menu = Array.new
  @menu.push(["main", "d"])
  @menu.push(["settings", "c"])
  @menu.push(["logout", "c"])

  @relates_array = Array.new

  if params[:twitter_data_id]
    id = params[:twitter_data_id] 
    
    twitter_oauth = Twitter_oauth.where(:uid => current_user.id).first
 
    configure_twitter_token(twitter_oauth.twitter_access_token, twitter_oauth.twitter_access_token_secret)
    @twitter = Twitter::Client.new
        
    @content = twitter_data_create(id)
  
  elsif params[:tumblr_data_id]
    id = params[:tumblr_data_id]
    
    tumblr_oauth = Tumblr_oauth.where(:uid => current_user.id).first

    configure_tumblr_token(tumblr_oauth.tumblr_access_token, tumblr_oauth.tumblr_access_token_secret)
    @tumblr = Tumblife.client
      
    @content = tumblr_data_create(id)  

  elsif params[:instagram_data_id]
    id = params[:instagram_data_id]
    
    instagram_oauth = Instagram_oauth.where(:uid => current_user.id).first

    @instagram = Instagram.client(:access_token => instagram_oauth.instagram_access_token)
    
	@content = instagram_data_create(id)     

  elsif params[:hatena_data_id]
    id = params[:hatena_data_id]
    
    hatena_oauth = Hatena_oauth.where(:uid => current_user.id).first

    access_token = OAuth::AccessToken.new(
      hatena_oauth_consumer,
      hatena_oauth.hatena_access_token,
      hatena_oauth.hatena_access_token_secret)
    
    @content = hatena_data_create(id)       
    
  elsif params[:evernote_data_id]
    id = params[:evernote_data_id]    
    evernote_oauth = Evernote_oauth.where(:uid => current_user.id).first
    @content = evernote_data_create(id)          
  
  else
  
  end

  #p @main_data
  haml :individual
  #"Hello"

end

#処理しきれてないので...後getで大丈夫？
get "/reject/:app" do

  case params[:app]
    when "twitter"
      Twitter_oauth.where(:uid => current_user.id).delete
      Tweets.where(:user_id => current_user.id).delete
      Tags.where(:user_id => current_user.id, :app => "twitter").delete
      
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
  
  redirect "/settings"

end

get "/:name/:page" do
#get "/:name" do
  #@uuid = UUIDTools::UUID.random_create
  if request.env["warden"].user.nil?
    redirect "/"
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
      case elem.app
        when "twitter"
      
          twitter_oauth = Twitter_oauth.where(:uid => current_user.id).first
 
          configure_twitter_token(twitter_oauth.twitter_access_token, twitter_oauth.twitter_access_token_secret)
          @twitter = Twitter::Client.new
        
          data_hash = twitter_data_create(elem.data_id)
          @contents_array.push(data_hash)
      
        when "tumblr"
      
          tumblr_oauth = Tumblr_oauth.where(:uid => current_user.id).first

          configure_tumblr_token(tumblr_oauth.tumblr_access_token, tumblr_oauth.tumblr_access_token_secret)
          @tumblr = Tumblife.client
      
          data_hash = tumblr_data_create(elem.data_id)
          @contents_array.push(data_hash)
       
        when "instagram"
      
          instagram_oauth = Instagram_oauth.where(:uid => current_user.id).first

		  @instagram = Instagram.client(:access_token => instagram_oauth.instagram_access_token)
    
	      data_hash = instagram_data_create(elem.data_id)
          @contents_array.push(data_hash)
      
      
        when "hatena"
        
          hatena_oauth = Hatena_oauth.where(:uid => current_user.id).first

          access_token = OAuth::AccessToken.new(
            hatena_oauth_consumer,
            hatena_oauth.hatena_access_token,
            hatena_oauth.hatena_access_token_secret)
    
		  data_hash = hatena_data_create(elem.data_id)

          @contents_array.push(data_hash)
      
      
        when "evernote"
      
          @evernote_oauth = Evernote_oauth.where(:uid => current_user.id).first
          data_hash = evernote_data_create(elem.data_id)
          @contents_array.push(data_hash)
      
        else
          
      end
    
    end
  
    haml :tagsearch
    #"Hello world" + params[:name] + params[:page]
  end
end
