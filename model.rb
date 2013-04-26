require 'sequel'

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

class Twitter_favorites < Sequel::Model
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
      foreign_key :data_id, :table => :Rss_items
      varchar :refrection
      foreign_key :channel_id, :table => :Rss_channels
    end
    create_table
  end
end

class Rss_item < Sequel::Model
  unless table_exists?
    set_schema do
      primary_key :data_id
      foreign_key :channel_id, :table => :RSS_channels
      varchar :title
      varchar :url
      varchar :date
      varchar :description
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

class Main_log < Sequel::Model
  unless table_exists?
    set_schema do
      primary_key :log_id
      varchar :user_id
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
      varchar :data_id
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
      varchar :data_id
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
    end
    create_table
  end
end

class Log_dataset < Sequel::Model
  unless table_exists?
    set_schema do
      varchar :log_id
      varchar :data_id
    end
    create_table
  end
end  
