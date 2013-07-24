#! ruby -Ku
# -*- coding: utf-8 -*-

class Oauth_register < Sinatra::Base

	enable :sessions
	
	before do
		@conf = YAML.load_file("../config.yaml")
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

	  session[:apps].push("twitter_f")
	  session[:apps].push("twitter_h")
	  session[:apps].push("twitter_u")
	  session[:apps].push("twitter_m")	  
	  
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
	
	  token = session.delete :token
	  flickr.get_access_token(token["oauth_token"], token['oauth_token_secret'], params[:oauth_verifier])
	
	  session[:flickr_access_token] = flickr.access_token  
	  session[:flickr_access_token_secret] = flickr.access_secret
	
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

		session[:apps].push("flickr")
		session[:apps].push("flickr_f")
	    
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
end