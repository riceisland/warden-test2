#! ruby -Ku
# -*- coding: utf-8 -*-

class Login < Sinatra::Base

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
	
	
	# 認証を実行する。
	# 成功すれば設定ページに移動。
	post "/login" do
	
	  if params[:name] != "" || params[:password] != ""
	    request.env["warden"].authenticate!
	    #redirect to ("/data_refresh")
	    redirect to ("/main")
	  else
	    redirect to ("/unauthenticated")
	  end
	
	end
	
	#get-login（URL直打ちパターン）
	get "/login" do  
	  if request.env["warden"].user.nil?
	  
	    @menu = Array.new
	    @menu.push(["top", ""])
	    @menu.push(["about", ""])
	    @menu.push(["login", "pure-menu-selected"])
	    @menu.push(["register", ""])
	
	    haml :login
	  else
	    redirect to ("/data_refresh")   
		#redirect to ("/main")
	  end
	end
	
	
	# 認証に失敗したとき呼ばれるルート。
	# ログイン失敗ページを表示してみる。
	#redirectで吹っ飛ばす推奨
	post "/unauthenticated" do
	  
	  @menu = Array.new 
	  @menu.push(["top", ""])
	  @menu.push(["about", ""])
	  @menu.push(["login", "pure-menu-selected"])
	  @menu.push(["register", ""])
	  
	  @msg = "ログインできませんでした。やり直してください。"
	
	  haml :fail_login
	end
	
	get "/unauthenticated" do
	  
	  @menu = Array.new
	  @menu.push(["top", ""])
	  @menu.push(["about", ""])
	  @menu.push(["login", "pure-menu-selected"])
	  @menu.push(["register", ""])
	  @msg = "ログインできませんでした。やり直してください。"
	  
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
	    @menu.push(["top", ""]) 
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
	  
	    if session[:msg]
	      @menu = Array.new
	      @menu.push(["top", ""])
	      @menu.push(["about", ""])
	      @menu.push(["login", ""])
	      @menu.push(["register", "pure-menu-selected"])
	      @msg = session[:msg]
	    
	      session.delete(:msg)
	
	      haml :fail_register
	  
	    else
	      redirect to ("/")
	    end
	  
	  else
	    redirect to ("/main")
	  end
	end
	
	post "/register" do
	  if params[:name] != "" && params[:password] != "" && params[:re_password] != "" && params[:mail] != ""
	    u = User.where(:name => params[:name]).first
	    
	    if u
	      session[:msg] = "そのユーザ名は使用済みです。別の名前に変更して下さい。"
	      redirect to ("/register/error") 
	    
	    else   
	    
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
	        session[:msg] = "パスワードが一致しませんでした。もう一度入力して下さい。"
	        redirect to ("/register/error")
	      end
	      
	    end
	    
	  else
	    session[:msg] = "記入漏れがあります。"
	    redirect to ("/register/error")
	  end
	end
end