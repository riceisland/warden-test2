#! ruby -Ku
# -*- coding: utf-8 -*-

class Ques < Sinatra::Base

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


	get "/ques" do
	
	  if request.env["warden"].user.nil?
	    redirect to ("/")
	  else
	  
	    sql = User.select(:b_ques).where(:id => current_user.id).first
	    
	    #if sql.b_ques == 0
	    
	      haml :ques, :layout => false
	    
	    #else
	    #  redirect to ("/")
	    #end
	    
	  end
	
	end
	
	post "/b_ques" do
	  
	  @uid = current_user.id
	  
	  @twitter_use = params[:twitter]
	  @flickr_use = params[:flickr]
	  @bkm_use = params[:bkm]
	
	  haml :b_ques, :layout => false
	
	end
	
	get "/b_ques" do
	 
	  if request.env["warden"].user.nil?
	    redirect to ("/")
	  else
	  
	    sql = User.select(:b_ques).where(:id => current_user.id).first
	    
	    if sql.b_ques == 0
	
	      haml :b_ques, :layout => false
	
	    else
	      redirect to ("/")
	    end
	    
	  end 
	
	end
	
	post "/b_ques_end" do
	
	  @menu = Array.new
	  @menu.push(["top", ""])
	  @menu.push(["about", ""])
	  @menu.push(["main", ""])
	  @menu.push(["settings", ""])
	  @menu.push(["logout", ""])
	
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
	    :uid => current_user.id,
	    :time => time,
	    :twitter => params[:twitter_use],
	    :flickr => params[:flickr_use],
	    :bookmark => params[:bkm_use],
	    :usingTime => params[:usingTime],
	    :useBrowser => params[:useBrowser],
	    :device_t => device["t"],
	    :device_f_r => device["fr"],
	    :device_f_s => device["fs"],
	    :device_b_r => device["br"],
	    :device_b_s => device["bs"],
	  })
	  
	  sql = B_User.select(:id).where(:uid => current_user.id).first
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
	  
	  if params[:twitter_use] == "0"
		  
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
		  
			  
	  end
	  
	  if params[:flickr_use] == "0"  
	  
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
		
		  
	  end
	  
	  if params[:bkm_use] == "0"
	  
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
	  end
	
	  User.where(:id => current_user.id).update(:b_ques => 1)

	  haml :end_ques
	  
	end


	post "/a_ques" do
	  
	  @uid = current_user.id
	  
	  @twitter_use = params[:twitter]
	  @flickr_use = params[:flickr]
	  @bkm_use = params[:bkm]
	
	  haml :a_ques, :layout => false
	
	end

	
	get "/a_ques" do
	 
	  if request.env["warden"].user.nil?
	    redirect to ("/")
	  else
	  
	    sql = User.select(:a_ques).where(:id => current_user.id).first
	    
	    if sql.a_ques = 0
	
	     # haml :a_ques, :layout => false
	      redirect to ("/")
	    else
	      redirect to ("/")
	    end
	    
	  end 
	
	end
	
	post "/a_ques_end" do
	
		@menu = Array.new
	    @menu.push(["top", ""])	
	  	@menu.push(["about", ""])
	    @menu.push(["main", ""])
	    @menu.push(["settings", ""])
	    @menu.push(["logout", ""])
	    
	  rrq = params[:rrq]
	  iact_t = params[:iact_t]
	  iact_f = params[:iact_f]
	  iact_b = params[:iact_b]
	  tv_t = params[:tv_t]
	  tv_f = params[:tv_f]
	  tv_b = params[:tv_b]
	
	  time = Time.now.to_s
	  
	   params[:useful_reason].force_encoding ("UTF-8")
	
	  A_User.create({
	    :uid => current_user.id,
	    :time => time,
	    :usingFreq => params[:usingFreq],
	    :useful => params[:useful],
	    :useful_reason => params[:useful_reason],
	    :free => params[:free],
	  })
	
	  sql = A_User.select(:id).where(:uid => current_user.id).first
	  id = sql.id
	  p id
	
	  A_RRQ.create({
	  	:id => id,
	  	:rrq_1 => rrq["1"],
	  	:rrq_2 => rrq["2"],
	  	:rrq_3 => rrq["3"],
	  	:rrq_4 => rrq["4"],
	  	:rrq_5 => rrq["5"],
	  	:rrq_6 => rrq["6"],
	  	:rrq_7 => rrq["7"],
	  	:rrq_8 => rrq["8"],
	  	:rrq_9 => rrq["9"],
	  	:rrq_10 => rrq["10"],
	  	:rrq_11 => rrq["11"],
	  	:rrq_12 => rrq["12"],
	  })

	  if params[:twitter_use] == "0"
	  
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
	  end

	  if params[:flickr_use] == "0"  	  	  
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
		  
	  end

	  if params[:bkm_use] == "0"	  	  
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
	  end
	  
	  User.filter(:id => params[:user]).update(:a_ques => 1)
	  
	  haml :end_ques
	
	end
end