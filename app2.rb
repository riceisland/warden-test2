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
require 'yaml'
require 'redis'
require 'flickraw'

#require "sinatra/reloader" if development?

#evernote用
require "./evernote_config"

require "./model.rb"
require './job'

require_relative './lib/data.rb'
require "./extract"


# Sinatra のセッションを有効にする
set :public_folder, File.join(File.dirname(__FILE__) , %w{ . public })
enable :sessions
use Rack::Session::Cookie, :secret => Digest::SHA1.hexdigest(rand.to_s)
#use Rack::MethodOverride
#enable :method_override 
#enable :static

#Setup redis for resque
#Resque.redis = Redis.new
Resque.redis = 'localhost:6379'

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
  @conf = YAML.load_file("config.yaml")

  @title = "まとめてらんだむ"
  #@prefix = "/mat_rnd"
  #@prefix = env["prefix"]
  Instagram.configure do |config|
    config.client_id = @conf["instagram_config"]["key"]
    config.client_secret = @conf["instagram_config"]["secret"]
  end
  
  #instagram用
  CALLBACK_URL = "http://localhost:4567/instagram_callback"
  #CALLBACK_URL = "http://java.slis.tsukuba.ac.jp/log-ref/instagram_callback"
  
  FlickRaw.api_key = @conf["flickr_config"]["key"]
  FlickRaw.shared_secret = @conf["flickr_config"]["secret"]
  #Flickr.configure do |config|
  #  config.api_key = @conf["flickr_config"]["key"]
  #  config.shared_secret = @conf["flickr_config"]["secret"]
  #end

end

def configure_twitter_token(token, secret)
  Twitter.configure do |config|
    config.consumer_key = @conf["twitter_config"]["key"]
	config.consumer_secret = @conf["twitter_config"]["secret"]
    config.oauth_token = token
    config.oauth_token_secret = secret
  end
end

def configure_tumblr_token(token, secret)
  Tumblife.configure do |config|
    config.consumer_key = @conf["tumblr_config"]["key"]
	config.consumer_secret = @conf["tumblr_config"]["secret"]
	config.oauth_token = token
	config.oauth_token_secret = secret
  end
end


def base_url
  default_port = (request.scheme == "http") ? 80 : 443
  port = (request.port == default_port) ? "" : ":#{request.port.to_s}"
  "#{request.scheme}://#{request.host}#{port}"
end

def twitter_oauth_consumer
  return OAuth::Consumer.new(@conf["twitter_config"]["key"],@conf["twitter_config"]["secret"], :site => "https://twitter.com")
end

def tumblr_oauth_consumer
  OAuth::Consumer.new(@conf["tumblr_config"]["key"], @conf["tumblr_config"]["secret"], {site:  "http://www.tumblr.com"})
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

# 認証方式を登録。

Warden::Strategies.add :login_test do
  # 認証に必要なデータが送信されているか検証
  def valid?
    params["name"] || params["password"]
  end

  # 認証
  def authenticate!
  p params["password"]
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
  	@menu.push(["about", ""])
    @menu.push(["login", ""])
    @menu.push(["register", ""])
    #erb :login
    haml :top
  else
    redirect to ('/main')
  end
end

# 認証を実行する。
# 成功すれば設定ページに移動。
post "/login" do

  if params[:name] != "" || params[:password] != ""
    request.env["warden"].authenticate!
    redirect to ("/data_refresh")
    #redirect to ("/main")
  else
    redirect to ("/unauthenticated")
  end

end

#get-login（URL直打ちパターン）
get "/login" do  
  if request.env["warden"].user.nil?
  
    @menu = Array.new
    @menu.push(["about", ""])
    @menu.push(["login", "pure-menu-selected"])
    @menu.push(["register", ""])

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
  @menu.push(["about", ""])
  @menu.push(["login", "pure-menu-selected"])
  @menu.push(["register", ""])
  #erb :fail_login
  haml :fail_login
end

get "/unauthenticated" do
  
  @menu = Array.new
  @menu.push(["about", ""])
  @menu.push(["login", "pure-menu-selected"])
  @menu.push(["register", ""])
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
    @menu.push(["about", ""])
    @menu.push(["login", ""])
    @menu.push(["register", "pure-menu-selected"])

    haml :register
  else
    redirect to ("/main")
  end
end

get "/register/error" do
  if request.env["warden"].user.nil?
    @menu = Array.new
    @menu.push(["about", ""])
    @menu.push(["login", ""])
    @menu.push(["register", "pure-menu-selected"])

    haml :fail_register
  else
    redirect to ("/main")
  end
end

post "/register" do
  if params[:name] != "" && params[:password] != "" && params[:re_password] != "" && params[:mail] != ""
    if params[:password] == params[:re_password]
      hexpass = OpenSSL::Digest::SHA1.hexdigest(params["password"])
      User.create({
	    :name => params[:name],
       :password => hexpass,
	  })
	  #登録と同時にログイン処理をしておく
	  request.env["warden"].authenticate!
      #redirect to("/settings")
      redirect to ("/ques")
    else
      redirect to ("/register/error")
    end
  else
    redirect to ("/register/error")
  end
end

get "/ques" do

  if request.env["warden"].user.nil?
    redirect to ("/")
  else
  
    sql = User.select(:b_ques).where(:id => current_user.id).first
    
    if sql.b_ques = 0
    
      haml :ques, :layout => false
    
    else
      redirect to ("/")
    end
    
  end

end

post "/b_ques" do
  
  @uid = current_user.id

  haml :b_ques, :layout => false

end

post "/b_ques_end" do

  device = params[:device]
  rrq = params[:rrq]
  iact_t = params[:iact_t]
  iact_f = params[:iact_f]
  iact_b = params[:iact_b]
  tv_t = params[:tv_t]
  tv_f = params[:tv_f]
  tv_b = params[:tv_b]
  
  time = Time.now.to_s
  
  B_User.create({
    :uid => params[:uid],
    :time => time,
    :usingTime => params[:usingTime],
    :useBrowser => params[:useBrowser],
    :device_t => device["t"],
    :device_f_r => device["fr"],
    :device_f_s => device["fs"],
    :device_b_r => device["br"],
    :device_b_s => device["bs"],
  })
  
  sql = B_User.select(:id).where(:uid => params[:uid]).first
  id = sql.id
  p id
  
  B_RRQ.create({
  	:id => id,
  	:rrq_1 => rrq["1"],
  	:rrq_2 => rrq["2"],
  	:rrq_1 => rrq["3"],
  	:rrq_1 => rrq["4"],
  	:rrq_1 => rrq["5"],
  	:rrq_1 => rrq["6"],
  	:rrq_1 => rrq["7"],
  	:rrq_1 => rrq["8"],
  	:rrq_1 => rrq["9"],
  	:rrq_1 => rrq["10"],
  	:rrq_1 => rrq["11"],
  	:rrq_1 => rrq["12"],
  })
  
  B_iact_t.create({
  	:id => id,
  	:iact_t_1 => iact_t["1"],
  	:iact_t_2 => iact_t["2"],
  	:iact_t_3 => iact_t["3"],
  	:iact_t_4 => iact_t["4"],
  	:iact_t_5 => iact_t["5"],
  	:iact_t_6 => iact_t["6"],
  	:iact_t_7 => iact_t["7"],
  	:iact_t_8 => iact_t["8"],
  	:iact_t_9 => iact_t["9"],
  	:iact_t_10 => iact_t["10"],
  	:iact_t_11 => iact_t["11"],
  	:iact_t_12 => iact_t["12"],
  	:iact_t_13 => iact_t["13"],
  	:iact_t_14 => iact_t["14"],
    :iact_t_15 => iact_t["15"],
    :iact_t_16 => iact_t["16"],
  })
  
  B_iact_f.create({
  	:id => id,
  	:iact_f_1 => iact_f["1"],
  	:iact_f_2 => iact_f["2"],
  	:iact_f_3 => iact_f["3"],
  	:iact_f_4 => iact_f["4"],
  	:iact_f_5 => iact_f["5"],
  	:iact_f_6 => iact_f["6"],
  	:iact_f_7 => iact_f["7"],
  	:iact_f_8 => iact_f["8"],
  	:iact_f_9 => iact_f["9"],
  	:iact_f_10 => iact_f["10"],
  	:iact_f_11 => iact_f["11"],
  	:iact_f_12 => iact_f["12"],
  	:iact_f_13 => iact_f["13"],
  	:iact_f_14 => iact_f["14"],
    :iact_f_15 => iact_f["15"],
    :iact_f_16 => iact_f["16"],
  })
  
  B_iact_b.create({
  	:id => id,
  	:iact_b_1 => iact_b["1"],
  	:iact_b_2 => iact_b["2"],
  	:iact_b_3 => iact_b["3"],
  	:iact_b_4 => iact_b["4"],
  	:iact_b_5 => iact_b["5"],
  	:iact_b_6 => iact_b["6"],
  	:iact_b_7 => iact_b["7"],
  	:iact_b_8 => iact_b["8"],
  	:iact_b_9 => iact_b["9"],
  	:iact_b_10 => iact_b["10"],
  	:iact_b_11 => iact_b["11"],
  	:iact_b_12 => iact_b["12"],
  	:iact_b_13 => iact_b["13"],
  	:iact_b_14 => iact_b["14"],
    :iact_b_15 => iact_b["15"],
    :iact_b_16 => iact_b["16"],
  })
  
  B_tv_t.create({
  	:id => id,
  	:tv_t_1 => tv_t["1"],
  	:tv_t_2 => tv_t["2"],
  	:tv_t_3 => tv_t["3"],
  	:tv_t_4 => tv_t["4"],
  	:tv_t_5 => tv_t["5"],
  	:tv_t_6 => tv_t["6"],
  	:tv_t_7 => tv_t["7"],
  	:tv_t_8 => tv_t["8"],
  	:tv_t_9 => tv_t["9"],
  	:tv_t_10 => tv_t["10"],
  	:tv_t_11 => tv_t["11"],
  	:tv_t_12 => tv_t["12"],
  })
  
  B_tv_f.create({
  	:id => id,
  	:tv_f_1 => tv_f["1"],
  	:tv_f_2 => tv_f["2"],
  	:tv_f_3 => tv_f["3"],
  	:tv_f_4 => tv_f["4"],
  	:tv_f_5 => tv_f["5"],
  	:tv_f_6 => tv_f["6"],
  	:tv_f_7 => tv_f["7"],
  	:tv_f_8 => tv_f["8"],
  	:tv_f_9 => tv_f["9"],
  	:tv_f_10 => tv_f["10"],
  	:tv_f_11 => tv_f["11"],
  	:tv_f_12 => tv_f["12"],
  })
  
  B_tv_b.create({
  	:id => id,
  	:tv_b_1 => tv_b["1"],
  	:tv_b_2 => tv_b["2"],
  	:tv_b_3 => tv_b["3"],
  	:tv_b_4 => tv_b["4"],
  	:tv_b_5 => tv_b["5"],
  	:tv_b_6 => tv_b["6"],
  	:tv_b_7 => tv_b["7"],
  	:tv_b_8 => tv_b["8"],
  	:tv_b_9 => tv_b["9"],
  	:tv_b_10 => tv_b["10"],
  	:tv_b_11 => tv_b["11"],
  	:tv_b_12 => tv_b["12"],
  })

  User.filter(:id => params[:user]).update(:b_ques => 1)

  p "回答を登録しました。"
  
end

post "/a_ques" do
  
  @uid = current_user.id

  haml :a_ques, :layout => false

end

post "/a_ques_end" do

  rrq = params[:rrq]
  iact_t = params[:iact_t]
  iact_f = params[:iact_f]
  iact_b = params[:iact_b]
  tv_t = params[:tv_t]
  tv_f = params[:tv_f]
  tv_b = params[:tv_b]

  time = Time.now.to_s

  A_User.create({
    :uid => params[:uid],
    :time => time,
    :usingFreq => params[:usingFreq],
    :useful => params[:useful],
    :useful_reason => params[:useful_reason],
    :free => params[:free],
  })

  sql = A_User.select(:id).where(:uid => params[:uid]).first
  id = sql.id
  p id

  A_RRQ.create({
  	:id => id,
  	:rrq_1 => rrq["1"],
  	:rrq_2 => rrq["2"],
  	:rrq_1 => rrq["3"],
  	:rrq_1 => rrq["4"],
  	:rrq_1 => rrq["5"],
  	:rrq_1 => rrq["6"],
  	:rrq_1 => rrq["7"],
  	:rrq_1 => rrq["8"],
  	:rrq_1 => rrq["9"],
  	:rrq_1 => rrq["10"],
  	:rrq_1 => rrq["11"],
  	:rrq_1 => rrq["12"],
  })
  
  A_iact_t.create({
  	:id => id,
  	:iact_t_1 => iact_t["1"],
  	:iact_t_2 => iact_t["2"],
  	:iact_t_3 => iact_t["3"],
  	:iact_t_4 => iact_t["4"],
  	:iact_t_5 => iact_t["5"],
  	:iact_t_6 => iact_t["6"],
  	:iact_t_7 => iact_t["7"],
  	:iact_t_8 => iact_t["8"],
  	:iact_t_9 => iact_t["9"],
  	:iact_t_10 => iact_t["10"],
  	:iact_t_11 => iact_t["11"],
  	:iact_t_12 => iact_t["12"],
  	:iact_t_13 => iact_t["13"],
  	:iact_t_14 => iact_t["14"],
    :iact_t_15 => iact_t["15"],
    :iact_t_16 => iact_t["16"],
  })
  
  A_iact_f.create({
  	:id => id,
  	:iact_f_1 => iact_f["1"],
  	:iact_f_2 => iact_f["2"],
  	:iact_f_3 => iact_f["3"],
  	:iact_f_4 => iact_f["4"],
  	:iact_f_5 => iact_f["5"],
  	:iact_f_6 => iact_f["6"],
  	:iact_f_7 => iact_f["7"],
  	:iact_f_8 => iact_f["8"],
  	:iact_f_9 => iact_f["9"],
  	:iact_f_10 => iact_f["10"],
  	:iact_f_11 => iact_f["11"],
  	:iact_f_12 => iact_f["12"],
  	:iact_f_13 => iact_f["13"],
  	:iact_f_14 => iact_f["14"],
    :iact_f_15 => iact_f["15"],
    :iact_f_16 => iact_f["16"],
  })
  
  A_iact_b.create({
  	:id => id,
  	:iact_b_1 => iact_b["1"],
  	:iact_b_2 => iact_b["2"],
  	:iact_b_3 => iact_b["3"],
  	:iact_b_4 => iact_b["4"],
  	:iact_b_5 => iact_b["5"],
  	:iact_b_6 => iact_b["6"],
  	:iact_b_7 => iact_b["7"],
  	:iact_b_8 => iact_b["8"],
  	:iact_b_9 => iact_b["9"],
  	:iact_b_10 => iact_b["10"],
  	:iact_b_11 => iact_b["11"],
  	:iact_b_12 => iact_b["12"],
  	:iact_b_13 => iact_b["13"],
  	:iact_b_14 => iact_b["14"],
    :iact_b_15 => iact_b["15"],
    :iact_b_16 => iact_b["16"],
  })
  
  A_tv_t.create({
  	:id => id,
  	:tv_t_1 => tv_t["1"],
  	:tv_t_2 => tv_t["2"],
  	:tv_t_3 => tv_t["3"],
  	:tv_t_4 => tv_t["4"],
  	:tv_t_5 => tv_t["5"],
  	:tv_t_6 => tv_t["6"],
  	:tv_t_7 => tv_t["7"],
  	:tv_t_8 => tv_t["8"],
  	:tv_t_9 => tv_t["9"],
  	:tv_t_10 => tv_t["10"],
  	:tv_t_11 => tv_t["11"],
  	:tv_t_12 => tv_t["12"],
  })
  
  A_tv_f.create({
  	:id => id,
  	:tv_f_1 => tv_f["1"],
  	:tv_f_2 => tv_f["2"],
  	:tv_f_3 => tv_f["3"],
  	:tv_f_4 => tv_f["4"],
  	:tv_f_5 => tv_f["5"],
  	:tv_f_6 => tv_f["6"],
  	:tv_f_7 => tv_f["7"],
  	:tv_f_8 => tv_f["8"],
  	:tv_f_9 => tv_f["9"],
  	:tv_f_10 => tv_f["10"],
  	:tv_f_11 => tv_f["11"],
  	:tv_f_12 => tv_f["12"],
  })
  
  A_tv_b.create({
  	:id => id,
  	:tv_b_1 => tv_b["1"],
  	:tv_b_2 => tv_b["2"],
  	:tv_b_3 => tv_b["3"],
  	:tv_b_4 => tv_b["4"],
  	:tv_b_5 => tv_b["5"],
  	:tv_b_6 => tv_b["6"],
  	:tv_b_7 => tv_b["7"],
  	:tv_b_8 => tv_b["8"],
  	:tv_b_9 => tv_b["9"],
  	:tv_b_10 => tv_b["10"],
  	:tv_b_11 => tv_b["11"],
  	:tv_b_12 => tv_b["12"],
  })
  
  User.filter(:id => params[:user]).update(:a_ques => 1)
  
  p "回答を登録しました。"

end


get "/settings" do
  if request.env["warden"].user.nil?
    redirect to ("/")
  else
	@menu = Array.new
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
    end
    
    haml :"settings"
  end
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
     
  Resque.enqueue(DataCreate, current_user.id, "twitter",session[:twitter_access_token],session[:twitter_access_token_secret])
  
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
        
  end
  
  tumblr_data = TumblrData::TumblrData.new(current_user.id, session[:tumblr_access_token], session[:tumblr_access_token_secret])
  tumblr_data.tumblr_db_create() 
  
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
    
    instagram_data = InstagramData::InstagramData.new(current_user.id, session[:instagram_access_token])
    instagram_data.instagram_db_create()

  end
 
  session.delete(:instagram_access_token)
       
  redirect to ("/settings") 
end

get '/flickr_request_token' do
  token = flickr.get_request_token(:oauth_callback => to('check'))
  session[:token] = token
  redirect flickr.get_authorize_url(token['oauth_token'], :perms => 'delete')
end

get '/check' do
  #request_token = Flickr::OAuth::RequestToken.new(*session[:flickr_request_token])
  #p request_token
  token = session.delete :token
 # access_token = request_token.get_access_token(params[:oauth_verifier])
  flickr.get_access_token(token["oauth_token"], token['oauth_token_secret'], params[:oauth_verifier])
  
  #p flickr
  session[:flickr_access_token] = flickr.access_token
  #p flickr.token
  
  session[:flickr_access_token_secret] = flickr.access_secret
  #p flickr.secret
  
  session.delete(:flickr_request_token)

  redirect to('/flickr_set')
end

get '/flickr_set' do

  flickr_oauth = Flickr_oauth.where(:uid => current_user.id).first
  
  if flickr_oauth
 
  else
    Flickr_oauth.create({
      :uid => current_user.id,
      :flickr_access_token => session[:flickr_access_token],
      :flickr_access_token_secret => session[:flickr_access_token_secret], 
    })

    Resque.enqueue(DataCreate, current_user.id, "flickr", session[:flickr_access_token], session[:flickr_access_token_secret])
    
    session.delete(:flickr_access_token)
    session.delete(:flickr_access_token_secret) 
  
  end
  
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

    hatena_data = HatenaData::HatenaData.new(current_user.id)
    hatena_data.hatena_db_create(session[:hatena_access_token],session[:hatena_access_token_secret])
    
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
    @main = ""
  
    @menu = Array.new
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
    end
    
    tumblr_oauth = Tumblr_oauth.where(:uid => current_user.id).first
    if tumblr_oauth
      apps.push("tumblr")
    end
  
    instagram_oauth = Instagram_oauth.where(:uid => current_user.id).first
    if instagram_oauth
      apps.push("instagram")
    end

    flickr_oauth = Flickr_oauth.where(:uid => current_user.id).first
    if flickr_oauth
      apps.push("flickr")
      apps.push("flickr_f")
    end
        
    hatena_oauth = Hatena_oauth.where(:uid => current_user.id).first
    if hatena_oauth
      apps.push("hatena")
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
    
    #logref_data = LogRef::LogRefData.new   
    
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

#getで来られたときはとりあえずランダムで対応
get "/individual" do

  if request.env["warden"].user.nil?
    redirect to ("/")
  else
  
  	@menu = Array.new
  	@menu.push(["about", ""])
    @menu.push(["main", ""])
    @menu.push(["settings", ""])
    @menu.push(["logout", ""])
    
    app_list = ["twitter_f", "twitter_h", "tumblr", "instagram", "hatena", "evernote", "flickr"]
    rand_app = app_list.sample     

    @content = AllData.one_data_create(current_user.id,rand_app, "")     
    
    this_id = @content[:id]
    time = Time.now
  
    Individual_log.create({
      :user_id => current_user.id,
      :id => this_id,
      :time => time,
    })
    
    haml :individual

  end

end


post "/individual" do

  @menu = Array.new
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

put "/upload" do
  
  if params[:file]
    f = params[:file][:tempfile]
    file = f.read
    file.force_encoding("UTF-8")
    
        
    Resque.enqueue(BookmarkDataCreate, current_user.id, file)
    
    
    redirect to ("/settings")

  end 
end

post "/remove" do

=begin  
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
=end

  return "ok"

end

get "/about" do
 @menu = Array.new
 
  if request.env["warden"].user.nil?
  	@menu.push(["about", "pure-menu-selected"])
    @menu.push(["login", ""])
    @menu.push(["register", ""])
  else
  	@menu.push(["about", "pure-menu-selected"])
    @menu.push(["main", ""])
    @menu.push(["settings", ""])
    @menu.push(["logout", ""])
  end

  haml :about

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