require 'sequel'

#sequel使えるようにする
Sequel::Model.plugin(:schema)
Sequel.extension :pagination
Sequel.connect("sqlite://user.db")

class User < Sequel::Model
  plugin :validation_helpers
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
	  integer :shuffle
	end
	create_table
  end
end

class Twitter_favorites < Sequel::Model
  unless table_exists?
    set_schema do
	  primary_key :id
	  integer :user_id
	  integer :data_id
	  integer :refrection
	  integer :shuffle
	end
	create_table
  end
end

class Twitter_urls < Sequel::Model
  unless table_exists?
    set_schema do
      primary_key :id  
      integer :user_id
      varchar :title
      varchar :url
      varchar :issued
      varchar :description
      integer :default
      integer :refrection
      integer :shuffle
 	end
	create_table
  end
end  
     
class Twitter_media < Sequel::Model
  unless table_exists?
    set_schema do
      primary_key :id  
      integer :user_id
      varchar :url
      varchar :media_url
      varchar :issued
      integer :width
      integer :height
      integer :refrection
      integer :shuffle
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
	  integer :shuffle
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
      integer :shuffle
    end
    create_table
  end
end

class Flickr_oauth < Sequel::Model
  unless table_exists?
    set_schema do
      varchar :uid
      varchar :flickr_access_token
      varchar :flickr_access_token_secret
    end
    create_table
  end
end

class Flickr_photos < Sequel::Model
  unless table_exists?
    set_schema do
      primary_key :id
      integer :user_id
      varchar :data_id
      integer :refrection
      integer :shuffle
    end
    create_table
  end
end

class Flickr_favorites < Sequel::Model
  unless table_exists?
    set_schema do
      primary_key :id
      integer :user_id
      varchar :data_id
      integer :refrection
      integer :shuffle
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
      integer :shuffle
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
	  integer :shuffle
	end
	create_table
  end
end

class Rss_channel < Sequel::Model
  unless table_exists?
    set_schema do
      primary_key :channel_id
      varchar :link
      varchar :title
    end
    create_table
  end
end

class Rss_user_relate < Sequel::Model
  unless table_exists?
    set_schema do
      integer :user_id
      foreign_key :id, :table => :Rss_items
      varchar :refrection
      foreign_key :channel_id, :table => :Rss_channels
      integer :shuffle
    end
    create_table
  end
end

class Rss_item < Sequel::Model
  unless table_exists?
    set_schema do
      primary_key :id
      foreign_key :channel_id, :table => :RSS_channels
      varchar :title
      varchar :url
      varchar :date
      varchar :description
    end
    create_table
  end
end

class Browser_bookmarks < Sequel::Model
  unless table_exists?
    set_schema do
      primary_key :id  
      integer :user_id
      varchar :title
      varchar :url
      varchar :issued
      varchar :description
      integer :refrection
      integer :shuffle
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
	  varchar :time
	  varchar :app
	end
	create_table
  end
end  

class Comments < Sequel::Model
  unless table_exists?
    set_schema do
      primary_key :id
	  integer :user_id
	  varchar :data_id
	  varchar :comment
	  varchar :time
	  varchar :app
	end
	create_table
  end
end  

class Main_log < Sequel::Model
  unless table_exists?
    set_schema do
      primary_key :log_id
      varchar :user_id
      varchar :dataset
      varchar :time
    end
    create_table
  end
end

class Individual_log < Sequel::Model
  unless table_exists?
    set_schema do
      primary_key :log_id
      varchar :user_id
      varchar :id
      varchar :time
    end
    create_table
  end
end

class Reflection_log < Sequel::Model
  unless table_exists?
    set_schema do
      primary_key :log_id
      varchar :user_id
      varchar :id
      varchar :time
    end
    create_table
  end
end

class Search_log < Sequel::Model
  unless table_exists?
    set_schema do
      primary_key :log_id
      varchar :user_id
      varchar :time
      varchar :tag
      varchar :page
      varchar :dataset
    end
    create_table
  end
end

require 'sequel'

#sequel使えるようにする
Sequel::Model.plugin(:schema)
Sequel.extension :pagination
Sequel.connect("sqlite://user.db")

class B_User < Sequel::Model
 
  unless table_exists?
    set_schema do
	  primary_key :id
	  varchar :uid
	  varchar :time
	  varchar :twitter
	  varchar :flickr
	  varchar :bookmark
	  varchar :usingTime
	  varchar :useBrowser
	  varcahr :device_t
	  varcahr :device_f_r
	  varcahr :device_f_s
	  varcahr :device_b_r
	  varcahr :device_b_s
	end
	create_table
  end
  
end

class A_User < Sequel::Model
 
  unless table_exists?
    set_schema do
	  primary_key :id
	  varchar :uid
	  varchar :time
	  varchar :usingFreq
	  varchar :useful
	  varchar :useful_reason
	  varchar :free
	end
	create_table
  end
  
end

class B_RRQ < Sequel::Model
  unless table_exists?
    set_schema do
      foreign_key :id, :table => :B_User
      integer :rrq_1
      integer :rrq_2
      integer :rrq_3
      integer :rrq_4
      integer :rrq_5
      integer :rrq_6
      integer :rrq_7
      integer :rrq_8
      integer :rrq_9
      integer :rrq_10
      integer :rrq_11
      integer :rrq_12
    end
    create_table
  end
end

class A_RRQ < Sequel::Model
  unless table_exists?
    set_schema do
      foreign_key :id, :table => :A_User
      integer :rrq_1
      integer :rrq_2
      integer :rrq_3
      integer :rrq_4
      integer :rrq_5
      integer :rrq_6
      integer :rrq_7
      integer :rrq_8
      integer :rrq_9
      integer :rrq_10
      integer :rrq_11
      integer :rrq_12
    end
    create_table
  end
end

class B_iact_t < Sequel::Model
  unless table_exists?
    set_schema do
	  foreign_key :id, :table => :B_User
	  integer :iact_t_1
      integer :iact_t_2
      integer :iact_t_3
      integer :iact_t_4
	  integer :iact_t_5
      integer :iact_t_6
      integer :iact_t_7
      integer :iact_t_8
	  integer :iact_t_9
      integer :iact_t_10
      integer :iact_t_11
      integer :iact_t_12
	  integer :iact_t_13
      integer :iact_t_14
      integer :iact_t_15
      integer :iact_t_16
	end
	create_table
  end
end

class A_iact_t < Sequel::Model
  unless table_exists?
    set_schema do
	  foreign_key :id, :table => :A_User
	  integer :iact_t_1
      integer :iact_t_2
      integer :iact_t_3
      integer :iact_t_4
	  integer :iact_t_5
      integer :iact_t_6
      integer :iact_t_7
      integer :iact_t_8
	  integer :iact_t_9
      integer :iact_t_10
      integer :iact_t_11
      integer :iact_t_12
	  integer :iact_t_13
      integer :iact_t_14
      integer :iact_t_15
      integer :iact_t_16
	end
	create_table
  end
end


class B_iact_f < Sequel::Model
  unless table_exists?
    set_schema do
	  foreign_key :id, :table => :B_User
	  integer :iact_f_1
      integer :iact_f_2
      integer :iact_f_3
      integer :iact_f_4
	  integer :iact_f_5
      integer :iact_f_6
      integer :iact_f_7
      integer :iact_f_8
	  integer :iact_f_9
      integer :iact_f_10
      integer :iact_f_11
      integer :iact_f_12
	  integer :iact_f_13
      integer :iact_f_14
      integer :iact_f_15
      integer :iact_f_16
	end
	create_table
  end
end

class A_iact_f < Sequel::Model
  unless table_exists?
    set_schema do
	  foreign_key :id, :table => :A_User
	  integer :iact_f_1
      integer :iact_f_2
      integer :iact_f_3
      integer :iact_f_4
	  integer :iact_f_5
      integer :iact_f_6
      integer :iact_f_7
      integer :iact_f_8
	  integer :iact_f_9
      integer :iact_f_10
      integer :iact_f_11
      integer :iact_f_12
	  integer :iact_f_13
      integer :iact_f_14
      integer :iact_f_15
      integer :iact_f_16
	end
	create_table
  end
end

class B_iact_b < Sequel::Model
  unless table_exists?
    set_schema do
	  foreign_key :id, :table => :B_User
	  integer :iact_b_1
      integer :iact_b_2
      integer :iact_b_3
      integer :iact_b_4
	  integer :iact_b_5
      integer :iact_b_6
      integer :iact_b_7
      integer :iact_b_8
	  integer :iact_b_9
      integer :iact_b_10
      integer :iact_b_11
      integer :iact_b_12
	  integer :iact_b_13
      integer :iact_b_14
      integer :iact_b_15
      integer :iact_b_16
	end
	create_table
  end
end

class A_iact_b < Sequel::Model
  unless table_exists?
    set_schema do
	  foreign_key :id, :table => :A_User
	  integer :iact_b_1
      integer :iact_b_2
      integer :iact_b_3
      integer :iact_b_4
	  integer :iact_b_5
      integer :iact_b_6
      integer :iact_b_7
      integer :iact_b_8
	  integer :iact_b_9
      integer :iact_b_10
      integer :iact_b_11
      integer :iact_b_12
	  integer :iact_b_13
      integer :iact_b_14
      integer :iact_b_15
      integer :iact_b_16
	end
	create_table
  end
end

class B_tv_t < Sequel::Model
  unless table_exists?
    set_schema do
	  foreign_key :id, :table => :B_User
	  integer :tv_t_1
      integer :tv_t_2
      integer :tv_t_3
      integer :tv_t_4
	  integer :tv_t_5
      integer :tv_t_6
      integer :tv_t_7
      integer :tv_t_8
	  integer :tv_t_9
      integer :tv_t_10
      integer :tv_t_11
      integer :tv_t_12
	end
	create_table
  end
end

class A_tv_t < Sequel::Model
  unless table_exists?
    set_schema do
	  foreign_key :id, :table => :A_User
	  integer :tv_t_1
      integer :tv_t_2
      integer :tv_t_3
      integer :tv_t_4
	  integer :tv_t_5
      integer :tv_t_6
      integer :tv_t_7
      integer :tv_t_8
	  integer :tv_t_9
      integer :tv_t_10
      integer :tv_t_11
      integer :tv_t_12
	end
	create_table
  end
end

class B_tv_f < Sequel::Model
  unless table_exists?
    set_schema do
	  foreign_key :id, :table => :B_User
	  integer :tv_f_1
      integer :tv_f_2
      integer :tv_f_3
      integer :tv_f_4
	  integer :tv_f_5
      integer :tv_f_6
      integer :tv_f_7
      integer :tv_f_8
	  integer :tv_f_9
      integer :tv_f_10
      integer :tv_f_11
      integer :tv_f_12
	  integer :tv_f_13
      integer :tv_f_14
      integer :tv_f_15
      integer :tv_f_16
	end
	create_table
  end
end

class A_tv_f < Sequel::Model
  unless table_exists?
    set_schema do
	  foreign_key :id, :table => :A_User
	  integer :tv_f_1
      integer :tv_f_2
      integer :tv_f_3
      integer :tv_f_4
	  integer :tv_f_5
      integer :tv_f_6
      integer :tv_f_7
      integer :tv_f_8
	  integer :tv_f_9
      integer :tv_f_10
      integer :tv_f_11
      integer :tv_f_12
	end
	create_table
  end
end


class B_tv_b < Sequel::Model
  unless table_exists?
    set_schema do
	  foreign_key :id, :table => :B_User
	  integer :tv_b_1
      integer :tv_b_2
      integer :tv_b_3
      integer :tv_b_4
	  integer :tv_b_5
      integer :tv_b_6
      integer :tv_b_7
      integer :tv_b_8
	  integer :tv_b_9
      integer :tv_b_10
      integer :tv_b_11
      integer :tv_b_12
	end
	create_table
  end
end

class A_tv_b < Sequel::Model
  unless table_exists?
    set_schema do
	  foreign_key :id, :table => :A_User
	  integer :tv_b_1
      integer :tv_b_2
      integer :tv_b_3
      integer :tv_b_4
	  integer :tv_b_5
      integer :tv_b_6
      integer :tv_b_7
      integer :tv_b_8
	  integer :tv_b_9
      integer :tv_b_10
      integer :tv_b_11
      integer :tv_b_12
	end
	create_table
  end
end


class A_SUS < Sequel::Model
  unless table_exists?
    set_schema do
      foreign_key :id, :table => :A_User
      integer :sus_1
      integer :sus_2
      integer :sus_3
      integer :sus_4
      integer :sus_5
      integer :sus_6
      integer :sus_7
      integer :sus_8
      integer :sus_9
      integer :sus_10
      integer :sus_11
      integer :sus_12
    end
    create_table
  end
end

class Recruit < Sequel::Model
  unless table_exists?
    set_schema do
	  primary_key :id  
	  varchar :username
	  varchar :mail
	  varchar :question
	  integer :check
	  varchar :time
	end
	create_table
  end
end


