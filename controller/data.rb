#! ruby -Ku
# -*- coding: utf-8 -*-
require "warden"
require "sequel"
require "openssl"
require 'oauth'
require 'twitter'
require 'tumblife'
require 'multi_json'
require 'net/https'
require 'instagram'
require 'open-uri'
require 'nokogiri'
require 'feed-normalizer'
require 'kconv'
require 'json'
require 'yaml'
require 'flickraw'
require 'mechanize'

require "../evernote_config"
require "../extract"

module AllData

  def rand_id_sample(uid, app)

    content_ids = Array.new()

    case app
      when "twitter_f"
        ids = Twitter_favorites.select(:id, :shuffle).filter(:user_id => uid).all

      when "twitter_h"
        ids = Tweets.select(:id, :shuffle).filter(:user_id => uid).all

      when "twitter_m"
        ids = Twitter_media.select(:id, :shuffle).filter(:user_id => uid).all

      when "twitter_u"
        ids = Twitter_urls.select(:id, :shuffle).filter(:user_id => uid).all
    
      when "tumblr"
        ids = Tumblr_posts.select(:id, :shuffle).filter(:user_id => uid).all
    
      when "instagram"
        ids = Instagram_photos.select(:id, :shuffle).filter(:user_id => uid).all

      when "flickr"
        ids = Flickr_photos.select(:id, :shuffle).filter(:user_id => uid).all
      
      when "flickr_f"
        ids = Flickr_favorites.select(:id, :shuffle).filter(:user_id => uid).all
    
      when "hatena"
        ids = Hatena_bookmarks.select(:id, :shuffle).filter(:user_id => uid).all   
      
      when "evernote"
        ids = Evernote_notes.select(:id, :shuffle).filter(:user_id => uid).all
    
      when "rss"    
        ids = Rss_user_relate.select(:id, :shuffle).filter(:user_id => uid).all
      
      when "browser_bookmarks"    
        ids = Browser_bookmarks.select(:id, :shuffle).filter(:user_id => uid).all
      else
    end
    
    if ids
      
      ids0 = Array.new
      ids1 = Array.new
      
      ids.each do |elem|
        case elem.shuffle
          when 0
            ids0.push(elem.id)

          when 1
            ids1.push(elem.id)      
          end
      end
      
      if ids0.length > 0
        rand_id = ids0.sample
        
        case app
        when "twitter_f"
          Twitter_favorites.filter(:user_id => uid, :id => rand_id).update(:shuffle => 1)

        when "twitter_h"
          Tweets.filter(:user_id => uid, :id => rand_id).update(:shuffle => 1)

        when "twitter_m"
          Twitter_media.filter(:user_id => uid, :id => rand_id).update(:shuffle => 1)

        when "twitter_u"
          Twitter_urls.filter(:user_id => uid, :id => rand_id).update(:shuffle => 1)
            
        when "tumblr"
          Tumblr_posts.filter(:user_id => uid, :id => rand_id).update(:shuffle => 1)
    
        when "instagram"
          Instagram_photos.filter(:user_id => uid, :id => rand_id).update(:shuffle => 1)

        when "flickr"
          Flickr_photos.filter(:user_id => uid, :id => rand_id).update(:shuffle => 1)

        when "flickr_f"
          Flickr_favorites.filter(:user_id => uid, :id => rand_id).update(:shuffle => 1)
    
        when "hatena"
          Hatena_bookmarks.filter(:user_id => uid, :id => rand_id).update(:shuffle => 1)
      
        when "evernote"
          Evernote_notes.filter(:user_id => uid, :id => rand_id).update(:shuffle => 1)
    
        when "rss"    
          Rss_user_relate.filter(:user_id => uid, :id => rand_id).update(:shuffle => 1)
      
        when "browser_bookmarks"    
          Browser_bookmarks.filter(:user_id => uid, :id => rand_id).update(:shuffle => 1)
        else
        end
        
      else
        rand_id = ids1.sample
        
        #sql0 = "update twitter_favorites set shuffle = 0 where user_id = "  + uid.to_s + " and not id = " + rand_id
        sql =  "user_id = "  + uid.to_s + " and not id = " + rand_id.to_s

        case app
        when "twitter_f"
          Twitter_favorites.filter(sql).update(:shuffle => 0)

        when "twitter_h"
          Tweets.filter(sql).update(:shuffle => 0)
          
        when "twitter_m"
          Twitter_media.filter(sql).update(:shuffle => 0)

        when "twitter_u"
          Twitter_urls.filter(sql).update(:shuffle => 0)
            
        when "tumblr"
          Tumblr_posts.filter(sql).update(:shuffle => 0)
    
        when "instagram"
          Instagram_photos.filter(sql).update(:shuffle => 0)

        when "flickr"
          Flickr_photos.filter(sql).update(:shuffle => 0)

        when "flickr_f"
          Flickr_favorites.filter(sql).update(:shuffle => 0)
    
        when "hatena"
          Hatena_bookmarks.filter(sql).update(:shuffle => 0)
      
        when "evernote"
          Evernote_notes.filter(sql).update(:shuffle => 0)
    
        when "rss"    
          Rss_user_relate.filter(sql).update(:shuffle => 0)
      
        when "browser_bookmarks"    
          Browser_bookmarks.filter(sql).update(:shuffle => 0)
        else
        end

        
      end
      
    else 
      rand_id = ""
      
    end
    
    p rand_id  
    return rand_id

  end
  
  def ref_counter(app, id)

    case app
      when "twitter_f"
        ref_sql = Twitter_favorites.select(:refrection).filter(:id => id)
    
      when "twitter_h"
        ref_sql = Tweets.select(:refrection).filter(:id => id)
        
      when "twitter_m"
        ref_sql = Twitter_media.select(:refrection).filter(:id => id)

      when "twitter_u"
        ref_sql = Twitter_urls.select(:refrection).filter(:id => id)
    
      when "tumblr"
        ref_sql = Tumblr_posts.select(:refrection).filter(:id => id)
    
      when "instagram"
        ref_sql = Instagram_photos.select(:refrection).filter(:id => id)

      when "flickr"
        ref_sql = Flickr_photos.select(:refrection).filter(:id => id)

      when "flickr_f"
        ref_sql = Flickr_favorites.select(:refrection).filter(:id => id)
    
      when "hatena"
        ref_sql = Hatena_bookmarks.select(:refrection).filter(:id => id)
    
      when "evernote"
        ref_sql = Evernote_notes.select(:refrection).filter(:id => id)
      
      when "rss"
        ref_sql = Rss_user_relate.select(:refrection).filter(:id => id)
      
      when "browser_bookmarks"
        ref_sql = Browser_bookmarks.select(:refrection).filter(:id => id)
      else
    end
  
    ref_sql.each do |ref|
	  ref_count = ref.refrection
	  return ref_count
    end 
  end
  
  def ref_comment(app, id)
  
    ref_sql = Comments.filter(:data_id => id, :app => app)  
    comments = Array.new
  
    ref_sql.each do |ref|
	  h = {:comment => ref.comment, :time => ref.time}
	  comments.push(h)
    end 

    return comments
  
  end

  def tag_concat(app,id)
    tags = Tags.select(:tag).filter(:data_id => id, :app => app) 
    tag_concat = ""
    p tags
    tags.each do |tag|
      tag_concat = tag_concat + tag.tag + ","
    end
    tag_concat.chop!
    return tag_concat
  end

  def tag_a_concat(app,id)
    tags = Tags.select(:tag).filter(:data_id => id, :app => app) 
    tag_a_concat = ""
    tags.each do |tag|
      tag_html = "<a href= /tagsearch?tagname=" + tag.tag + "&page=1>" + tag.tag + "</a> "  
      tag_a_concat = tag_a_concat + tag_html
    end
    return tag_a_concat
  end
  
  def db_row_create(uid,app, id)
  
    case app
      when "twitter_f"
        Twitter_favorites.create({
	      :user_id => uid,
		  :data_id => id,
		  :refrection => 0,
		  :shuffle => 0,
	    })
	  when "twitter_h"
	     Tweets.create({
	       :user_id => uid,
		   :data_id => id,
	       :refrection => 0,
	       :shuffle => 0,
	     })
	   when "tumblr"
         Tumblr_posts.create({
           :user_id => uid,
           :data_id => id,
           :refrection => 0,
           :shuffle => 0,
         })
       when "instagram"
         Instagram_photos.create({
           :user_id => uid,
           :data_id => id,
           :refrection => 0,
           :shuffle => 0,
         })
       when "flickr"
         Flickr_photos.create({
           :user_id => uid,
           :data_id => id,
           :refrection => 0,
           :shuffle => 0,
         })       	      
       when "flickr_f"
         Flickr_favorites.create({
           :user_id => uid,
           :data_id => id,
           :refrection => 0,
           :shuffle => 0,
         }) 
       when "evernote"	 
         Evernote_notes.create({
           :user_id => uid,
           :data_id => id,
           :refrection => 0,
           :shuffle => 0,
         })
    end
  end
  
  def reject(uid,app)

    case app
      when "twitter"
        Twitter_oauth.where(:uid => uid).delete
        Twitter_favorites.where(:user_id => uid).delete
        Tweets.where(:user_id => uid).delete
		Twitter_urls.where(:user_id => uid).delete
		Twitter_media.where(:user_id => uid).delete
        Tags.where(:user_id => uid, :app => "twitter_f").delete
        Tags.where(:user_id => uid, :app => "twitter_h").delete
        Tags.where(:user_id => uid, :app => "twitter_u").delete
        Tags.where(:user_id => uid, :app => "twitter_m").delete
      
	  when "tumblr"
	    Tumblr_oauth.where(:uid => uid).delete
	    Tumblr_posts.where(:user_id => uid).delete
	    Tags.where(:user_id => uid, :app => "tumblr").delete
      
	  when "instagram"
	    Instagram_oauth.where(:uid => uid).delete
	    Instagram_photos.where(:user_id => uid).delete
	    Tags.where(:user_id => uid, :app => "instagram").delete
	  
      when "flickr"
	    Flickr_oauth.where(:uid => uid).delete
	    Flickr_photos.where(:user_id => uid).delete
	    Flickr_favorites.where(:user_id => uid).delete
	    Tags.where(:user_id => uid, :app => "flickr").delete
	    Tags.where(:user_id => uid, :app => "flickr_f").delete
	   
	  when "hatena"
	    Hatena_oauth.where(:uid => uid).delete
	    Hatena_bookmarks.where(:user_id => uid).delete
	    Tags.where(:user_id => uid, :app => "hatena").delete
	  
	  when "evernote"
	    Evernote_oauth.where(:uid => uid).delete
	    Evernote_notes.where(:user_id => uid).delete
	    Tags.where(:user_id => uid, :app => "evernote").delete
	  
	  when "browser_bookmarks"
	    Browser_bookmarks.where(:user_id => uid).delete
	    Tags.where(:user_id => uid, :app => "browser_bookmarks").delete

	  else
    end  

  end
  
  def one_data_create(uid,app, id)
  
    if id == ""
      id = AllData.rand_id_sample(uid,app)
    end

    if id == ""
    
      data_hash = ""
      
    else
    
    case app
      when "twitter_f"
      
        twitter_oauth = Twitter_oauth.where(:uid => uid).first
        twitter_data = TwitterData::TwitterData.new(uid, twitter_oauth.twitter_access_token, twitter_oauth.twitter_access_token_secret)
        data_hash = twitter_data.twitter_favs_data_create(id)
        p data_hash
          
      when "twitter_h"
      
        twitter_oauth = Twitter_oauth.where(:uid => uid).first
        twitter_data = TwitterData::TwitterData.new(uid, twitter_oauth.twitter_access_token, twitter_oauth.twitter_access_token_secret)       
        data_hash = twitter_data.twitter_home_data_create(id)

      when "twitter_m"
      
        twitter_oauth = Twitter_oauth.where(:uid => uid).first
        twitter_data = TwitterData::TwitterData.new(uid, twitter_oauth.twitter_access_token, twitter_oauth.twitter_access_token_secret)       
        data_hash = twitter_data.twitter_media_data_create(id)


      when "twitter_u"
        twitter_oauth = Twitter_oauth.where(:uid => uid).first
        twitter_data = TwitterData::TwitterData.new(uid, twitter_oauth.twitter_access_token, twitter_oauth.twitter_access_token_secret)    
        data_hash = twitter_data.twitter_url_data_create(id)
              
      when "tumblr"
      
        tumblr_oauth = Tumblr_oauth.where(:uid => uid).first
        tumblr_data = TumblrData::TumblrData.new(uid, tumblr_oauth.tumblr_access_token, tumblr_oauth.tumblr_access_token_secret)     
        data_hash = tumblr_data.tumblr_data_create(id)
       
      when "instagram"
      
        instagram_oauth = Instagram_oauth.where(:uid => uid).first
        instagram_data = InstagramData::InstagramData.new(uid, instagram_oauth.instagram_access_token)
        data_hash = instagram_data.instagram_data_create(id)
	  
	  when "flickr"
	  
	    flickr_oauth = Flickr_oauth.where(:uid => uid).first	  
	    flickr_data = FlickrData::FlickrData.new(uid, flickr_oauth.flickr_access_token, flickr_oauth.flickr_access_token_secret)      
        data_hash = flickr_data.flickr_data_create(id)
      
	  when "flickr_f"
	  
	    flickr_oauth = Flickr_oauth.where(:uid => uid).first	  
	    flickr_data = FlickrData::FlickrData.new(uid, flickr_oauth.flickr_access_token, flickr_oauth.flickr_access_token_secret)      
        data_hash = flickr_data.flickr_favs_data_create(id)

      when "hatena"

        hatena_bookmarks_data = HatenaData::HatenaData.new(uid)
        data_hash = hatena_bookmarks_data.hatena_data_create(id)
      
      when "evernote"
        
        evernote_data = EvernoteData::EvernoteData.new(uid)
        data_hash = evernote_data.evernote_data_create(id)
      
      when "rss"
        
        rss_data = RssData::RssData.new(uid)
        data_hash = rss_data.rss_data_create(id)
      
      when "browser_bookmarks"
    
        browser_bookmarks_data = BrowserBookmarkData::BrowserBookmarkData.new(uid)
        data_hash = browser_bookmarks_data.browser_bookmarks_data_create(id)
          
      else
          
    end
    end
    
    p data_hash
    
    return data_hash

  end

  def db_tag_create(uid, app, id, tag)
    time = Time.now.to_s
  
    Tags.create({
      :user_id => uid,
      :data_id => id,
      :tag => tag,
      :time => time,
      :app => app,
    })
  
  end

  def db_comment_create(uid,app, id, comment)

    time = Time.now.to_s
  
    Comments.create({
      :user_id => uid,
      :data_id => id,
      :comment => comment,
      :time => time,
      :app => app,
    })
  
    h = {:comment => comment, :time => time}
  
    return h
  
  end
  
  def tag_recreate(uid, id, tags, app)
    Tags.filter(:user_id => uid, :data_id => id).delete
   
    split_tag = tags.split(",")
   
    split_tag.each do |elem|
      elem.gsub!(/\s/, "")
      AllData.db_tag_create(uid,app, id, elem)
    end
  end
  
  def data_to_html(content)
    
    html = ""
    
    p content
  
    case content[:app]
      when "twitter_f"
        html << "<div id = '" + content[:id] + "' class = 'pin twitter'>"
        
        ref_rem = ref_and_remove(content[:app],content[:id], content[:ref_count])
        
        html << ref_rem
        
        html << "<div class='twitter_user'>"
        html << "<img src='" + content[:twitter_img_url] + "' class = 'icon'>"
        html << "<p class ='username'>" + content[:twitter_user_name] + "</p>"
        html << "<p class ='screenname'>@" + content[:twitter_screen_name] + "</p>"
        html << "</div>"
        html << "<div class='tweet'>"
        html << "<p class ='text'>" + content[:twitter_text] + "</p>"
        html << "<span class ='time'>" + content[:twitter_time].to_s + "</span>"
        html << 	"<a href='" + content[:url] + "' target = '_blank' class = 'detail'>詳細を見る</a>"
        html << "</div>"
        
        comment = comment_html(content[:id], content[:comment])
        
        html << comment
        html << "</div>"
          
      when "twitter_h"

        html << "<div id = '" + content[:id] + "' class = 'pin twitter'>"
        
        ref_rem = ref_and_remove(content[:app],content[:id], content[:ref_count])
        
        html << ref_rem
        
        html << "<div class='twitter_user'>"
        html << "<img src='" + content[:twitter_img_url] + "' class = 'icon'>"
        html << "<p class ='username'>" + content[:twitter_user_name] + "</p>"
        html << "<p class ='screenname'>@" + content[:twitter_screen_name] + "</p>"
        html << "</div>"
        html << "<div class='tweet'>"
        html << "<p class ='text'>" + content[:twitter_text] + "</p>"
        html << "<span class ='time'>" + content[:twitter_time].to_s + "</span>"
        html << "<a href='" + content[:url] + "' target = '_blank' class = 'detail'>詳細を見る</a>"
        html << "</div>"
        
        comment = comment_html(content[:id], content[:comment])
        
        html << comment
        html << "</div>"
        
      when "twitter_m"

        html << "<div id = '" + content[:id] + "' class = 'pin twitter'>"
        
        ref_rem = ref_and_remove(content[:app],content[:id], content[:ref_count])
        
        html << ref_rem
        
        html << "<img src='" + content[:twitter_media_url] + "' class = 'twitter_img' width = " + content[:width]  + " height=" + content[:height]  +" >"      
        html << "<span class ='time'>" + content[:twitter_issued].to_s + "</span>"
        html << "<a href='" + content[:twitter_url] + "' target = '_blank' class = 'detail'>詳細を見る</a>"
        #html << "</div>"      
      
        comment = comment_html(content[:id], content[:comment])
        
        html << comment
        html << "</div>"
      
      when "twitter_u"
      
        html << "<div id = '" + content[:id] + "' class = 'pin twitter'>"
        
        ref_rem = ref_and_remove(content[:app],content[:id], content[:ref_count])
        
        html << ref_rem      
      
        html << "<a href=" + content[:url] +" target='_blank'>" + content[:twitter_title] + "</a><br>"
        html << "<div class = 'description'>" + content[:twitter_description] + "</div>"
        html << "<span class='time'>" + content[:twitter_issued].to_s + "</span>"
		html << "<a href='" + content[:default_url] + "' target = '_blank' class = 'detail'>詳細を見る</a>"

        comment = comment_html(content[:id], content[:comment])
        html << comment   
	    html << "</div>"      
     
      when "tumblr"
      
        html << "<div id = '" + content[:id] + "' class = 'pin tumblr'>"
        
        ref_rem = ref_and_remove(content[:app],content[:id], content[:ref_count])
        
        html << ref_rem
        
        case content[:type]
          when "text"
            if content[:post_title]
              html << "<p>" + content[:post_title] + "</p>"   
            end
            
            html << "<p>" + content[:body] + "</p>"
          
          when "photo"
            if content[:layouts]
              html << "<div id = 'photoset'>"
              
              i = 0
              content[:layout].each do |num|
			    html << "<div class = 'row'" + num + ">"
				
				j = 0
				while j < num.to_i
				  j = j + 1
				  html << "<img src = " + content[:imgarr][i].alt_sizes[0].url + " class = 'photo" + num + " line"+ num + j.to_s + ">"
				end
				
				i = i + 1      
              end
            
            else
              html << "<div id = 'photo'>"
		      html << "<img src = " + content[:imgarr][0].alt_sizes[1].url + " class = 'photo'>"
		    end
		    
		    html << "<p>" + content[:caption] + "</p>" 
		  
		  when "quote"
            html << "<p>" + content[:text] + "</p>"   
            html << "<p>" + content[:source] + "</p>"
          
          when "link"
            if content[:post_title]
              html << "<p>" + content[:post_title] + "</p>"   
            end
            
            html << "<p>" + content[:url] + "</p>" 
            html << "<p>" + content[:description] + "</p>"
          
          when "chat"
            html << "<p>" + content[:post_title] + "</p>" 
            html << "<div id = 'chat'>"
            html << "<table><tbody>"
            
            content[:dialogue].each do |post|
            
              html << "<tr>"
              html << "<td>" + post.phrase + "</td>"
              html << "</tr>"
            
            end
            
            html << "</tbody></table></div>"
            
          when "audio"
            html << "<div id = 'code'>" + content[:code] + "</div>"
            html << "<div id = 'caption'>" + content[:caption] + "</div>"

          when "video"
          
            if content[:blogtitle]
              html << "<div id = 'title'>" + content[:blogtitle] + "</div>"
            end
            html << "<div id = 'code'>" + content[:code] + "</div>"
            html << "<div id = 'caption'>" + content[:caption] + "</div>"
          
          else 
        end          

        html << "<span class ='time'>" + content[:tumblr_time].to_s + "</span>"
        html << "<a href='" + content[:url] + "' target = '_blank' class = 'detail'>詳細を見る</a>"

        comment = comment_html(content[:id], content[:comment])
        
        html << comment
        html << "</div>"

      when "instagram"
        
        html << "<div id = '" + content[:id] + "' class = 'pin instagram'>"
        
        ref_rem = ref_and_remove(content[:app],content[:id], content[:ref_count])
        
        html << ref_rem
        
        html << "<img src ='" + content[:instagram_img_url] + "' id = 'instagram_img'>"
        
        if content[:instagram_text]
          html << "<p>" + content[:instagram_text] + "</p>" 
        else
          content[:instagram_text] = ""
          html << "<p>" + content[:instagram_text] + "</p>" 
        end
        
             
        html << "<span class ='time'>" + content[:instagram_time].to_s + "</span>"
        html << "<a href='" + content[:url] + "' target = '_blank' class = 'detail'>詳細を見る</a>" 
        
        comment = comment_html(content[:id], content[:comment])
        
        html << comment     
	    html << "</div>"
	  
	  when "flickr"
	    
	    html << "<div id = '" + content[:id] + "' class = 'pin instagram'>"
        
        ref_rem = ref_and_remove(content[:app],content[:id], content[:ref_count])
        
        html << ref_rem
        
        html << "<img src ='" + content[:flickr_img_url] + "' id = 'flickr_img'>"
        html << "<p>" + content[:flickr_title] + "</p>"      
        html << "<div class = 'description'>" + content[:flickr_text] + "</div>"
        
        html << "<span class ='time'>" + content[:flickr_time].to_s + "</span>"
        html << "<a href='" + content[:url] + "' target = '_blank' class = 'detail'>詳細を見る</a>" 
        
        comment = comment_html(content[:id], content[:comment])
        
        html << comment   
	    html << "</div>"

	  when "flickr_f"

	    html << "<div id = '" + content[:id] + "' class = 'pin instagram'>"
        
        ref_rem = ref_and_remove(content[:app],content[:id], content[:ref_count])
        html << ref_rem
        
        html << "<img src ='" + content[:flickr_img_url] + "' id = 'flickr_img'>"
        html << "<p>" + content[:flickr_title] + "</p>"      
        html << "<div class = 'description'>" + content[:flickr_text] + "</div>"
        
        html << "<span class ='time'>" + content[:flickr_time].to_s + "</span>"
        html << "<a href='" + content[:url] + "' target = '_blank' class = 'detail'>詳細を見る</a>" 
        
        comment = comment_html(content[:id], content[:comment])
        
        html << comment   
	    html << "</div>"


      when "hatena"
        html << "<div id = '" + content[:id] + "' class = 'pin hatena'>"
        
        ref_rem = ref_and_remove(content[:app],content[:id], content[:ref_count])
        html << ref_rem
        
        html << "<a href=" + content[:hatena_url] +" target='_blank'>" + content[:hatena_title] + "</a><br>"
        html << "<span class='time'>" + content[:hatena_issued].to_s + "</span>"


        comment = comment_html(content[:id], content[:comment])
        html << comment   
	    html << "</div>"
      
      when "evernote"
        html << "<div id = '" + content[:id] + "' class = 'pin evernote'>"
        
        ref_rem = ref_and_remove(content[:app],content[:id], content[:ref_count])
        html << ref_rem
        
        html << "<div id='snippet'>"
        html << "<div id = 'title'>" + content[:note_title] + "</div>"
        html << "<div id = 'body'>" + content[:snippet] + "</div>"
        html << "</div>"
        
        html << "<p id = 'viewall'>ViewAll→</p>"
        html << "<span class = 'time'>" + content[:evernote_time].to_s + "</span>"
        html << "<a href='" + content[:url] + "' target = '_blank' class = 'detail'>詳細を見る</a>" 
        
        html << "<div class = 'modal hide fade' id = 'allcontent' tabindex = '-1' role = 'dialog' aria-labelledby = 'ModalLabel' aria-hidden = 'true'>"
        
        html << "<div class = 'modal-header'>"
        html << "<button type = 'button' class = 'close' data-dismiss = 'modal' aria-hidden = 'true'>x"
        html << "<h3 id = 'ModalLabel'>" + content[:note_title] + "</h3>"
        html << "</div>"
        
        html << "<div class = 'modal-body'>"
        html << "<div>" + content[:content] + "</div>"
        html << "</div>"
        
        html << "<div class = 'modal-footer'>"
        html << "<a href = " + content[:url] + " class = 'btn' target = '_blank'>Edit</a>"
        html << "<button class = 'btn' data-dismiss = 'modal' aria-hidden = 'true'>Close"
        html << "</div>"
              
        comment = comment_html(content[:id], content[:comment])
        
        html << comment   
	    html << "</div>"
      
      when "rss"
        
        html << "<div id = '" + content[:id] + "' class = 'pin rss'>"
        
        ref_rem = ref_and_remove(content[:app],content[:id], content[:ref_count])
        html << ref_rem
        
        html << "<a href=" + content[:rss_url] +" target='_blank'>" + content[:rss_title] + "</a>"
        html << "<p>" + content[:rss_description] + "</p>"
        html << "<span class='time'>" + content[:rss_date].to_s + "</span>"


        comment = comment_html(content[:id], content[:comment])
        html << comment   
	    html << "</div>"
      
      when "browser_bookmarks"

        html << "<div id = '" + content[:id] + "' class = 'pin hatena'>"
        
        ref_rem = ref_and_remove(content[:app],content[:id], content[:ref_count])
        html << ref_rem
        
        html << "<a href=" + content[:bb_url] +" target='_blank'>" + content[:bb_title] + "</a><br>"
        html << "<div class = 'description'>" + content[:bb_description] + "</div>"
        html << "<span class='time'>" + content[:bb_issued].to_s + "</span>"


        comment = comment_html(content[:id], content[:comment])
        html.force_encoding("UTF-8")
        comment.force_encoding("UTF-8")
        html << comment   
	    html << "</div>"
          
      else
          
    end

  
    return html
  
  end
  
  def ref_and_remove(app, id, count)
  
    html = "<div class='ref_and_remove'>"
    
    html << "<div class ='remove'>"
    html << "<form class = 'remove'>"
    html << "<input type ='hidden' name = 'data_id' value = '" + id +"'>"
    html << "<input type ='hidden' name = 'app' value = '" + app +"'>"
    html << "<button type='submit' class='cancel'><i class='icon-cancel' id='cancel_" + id + "'></i></button></form></div>"
    
    #html << "<div class='reflection'>"
    #html << "<form class='ref_form'>"
    #html << "<input name='data_id' type='hidden' value='" + id + "'>"
    #html << "<input id='ref_val_" + id + "' name='ref_count' type='hidden' value='" + count.to_s + "'>"
    #html << "<button class='ui-btn ui-btn-up-e ui-shadow ui-btn-corner-all ui-btn-inline ui-btn-icon-notext' data-corners='true' data-icon='flat-checkround' data-iconpos='notext' data-iconshadow='true' data-inline='true' data-role='button' data-shadow='true' data-theme='e' data-wrapperels='span' title='Checkround' type='submit'><span class='ui-btn-inner'><span class='ui-btn-text'>Chrckround</span><span class='ui-icon ui-icon-flat-checkround ui-icon-shadow'></span></span></button></form></div>"
    
    html << "</div>" #ref_and_remove
    
    #html << "<span class='ref_count' id='ref_count_" + id + "'>" + count.to_s + "</span>"
    
    return html
  
  end
  
  
  
  def comment_html(id, comment)
  
    html = "<div class='tags clear' id='comments_" + id + "'>"    
    html << "<hr>"
    html << "<div class='comment_total' id='comment_total_" + id + "'>発見&コメント (" + comment.length.to_s + ")</div>"
    
    comment.each do |elem|
    
      html << "<div class='comment'>"
      html << "<div class='comment_text'>" + elem[:comment] + "</div>"
      html << "<div class='comment_time'>" + elem[:time] + "</div>"
      html << "</div>"
    
    end

    html << "</div>"    
    html << "<div class='comment_form' id='comment_form_" + id +"'>"
    html << "<form class='comment_form pure-form'>"
    html << "<input name='comment' placeholder='コメントがあればこちらに入力してください' type='text'>"
    html << "<input name='data_id' type='hidden' value='" + id +"'>"
    html << "<button class='pure-button notice' type='submit'>発見!</button></form></div>"
  
  end

  module_function :tag_recreate
  module_function :db_row_create
  module_function :db_tag_create
  module_function :db_comment_create
  module_function :rand_id_sample
  module_function :one_data_create
  module_function :reject
  module_function :data_to_html
  module_function :ref_and_remove
  module_function :comment_html

end

module TwitterData
  class TwitterData
  
  include AllData
  
  def initialize(uid,token, secret)
  
   @user_id = uid

   @conf = YAML.load_file("../config.yaml")
   
   @twitter = Twitter::Client.new(
     :consumer_key => @conf["twitter_config"]["key"],
     :consumer_secret => @conf["twitter_config"]["secret"],
     :oauth_token => token,
     :oauth_token_secret => secret
   )
   
   @agent = Mechanize.new

  end
  
  def twitter_media_db_create(user_id, elem,time)

    Twitter_media.create({
	  :user_id => user_id,
	  :media_url => elem.media_url,
	  :url => elem.url,
	  :issued => time,
	  :width => elem.sizes[:small][:w],
	  :height => elem.sizes[:small][:h],
	  :refrection => 0,
	  :shuffle => 0,
	})	
  
  end
  
  def twitter_url_db_create(user_id, elem, time, default_id)

    url = elem.expanded_url
	p url
	      		
	if url =~ /\Ahttps?\:\/\//
	  
	  begin
	    page = @agent.get(url)
	  
	  rescue
	  
	  else
	  
		  title = page.title
				
		  extractor = ExtractContent::Extractor.new
		  #p extractor
				
		  begin
			description = extractor.analyse(open(url).read)[0]    
			#p description
				          
		  rescue
			description = ""
				        
	      end
				      
		  unless description == ""
				       
			str =  description.split(//)
			len = str.length
				        
			if len > 200
			  new_str = str.slice(0, 200)
			  description = new_str.join("")
			end
				        
		  end
		  
		  p "--"
		      	
		  Twitter_urls.create({
		  	:user_id => @user_id,
		  	:title => title,
		  	:url => url,
		  	:issued => time,
		  	:description => description,
		  	:default => default_id,
		  	:refrection => 0,
		  	:shuffle => 0,
		  })	        	
	  
	   end     	
	end
  
  
  end
  
  def twitter_db_create() 

    begin
      
      @twitter.favorites({:count => 100, :include_entities => "1"}).each do |twit|
        
        p twit.id
  
        past_fav = Twitter_favorites.select(:id).filter(:user_id => @user_id, :data_id => twit.id.to_s).first

        if past_fav
          break
	    else
          db_row_create(@user_id,"twitter_f", twit.id.to_s)

	      if twit.media != []

			twit.media.each do |elem|
			
              twitter_media_db_create(@user_id, elem, twit.created_at)
              
	        end
	      	      
	      end
	      
	      if twit.urls != []
	      	
	      	twit.urls.each do |elem|
	      	  
	      	  twitter_url_db_create(@user_id, elem, twit.created_at, twit.id.to_s)
	      	
	        end
	      	      
	      end

	    end
	        
      end  #--each do
     
      @twitter.user_timeline(:count => 200).each do |twit|
   
        past_tweet = Tweets.select(:id).filter(:user_id => @user_id, :data_id => twit.id.to_s).first

        if past_tweet
          break
        else
	      db_row_create(@user_id,"twitter_h", twit.id.to_s)
	      
	      if twit.media != []

			twit.media.each do |elem|
			
              twitter_media_db_create(@user_id, elem, twit.created_at)
              
	        end
	      	      
	      end
	      
	      if twit.urls != []
	      	
	      	twit.urls.each do |elem|
	      	  
	      	  twitter_url_db_create(@user_id, elem, twit.created_at, twit.id.to_s)
	      	
	        end
	      	      
	      end
	      	      
	    end
	        
      end  #--each do
    
    rescue Twitter::Error::Unauthorized => error
	   
	  if error.to_s.index("Invalid or expired token")
        reject("twitter")
      end
	    
    rescue Twitter::Error::Forbidden => error
    
    rescue Twitter::Error::ClientError => error	    
	
    end
  end
  
  def twitter_home_data_create(id)

    ref_count = ref_counter("twitter_h", id)
    twit_id = Tweets.select(:data_id).filter(:id => id).first
    new_id = "twitter_h-" + id.to_s

    fav = @twitter.status(twit_id.data_id)
    
    @twitter_img_url = fav.user.profile_image_url 
    @twitter_user_name = fav.user.name
    @twitter_screen_name = fav.user.screen_name
    @twitter_text = fav.text
    @twitter_time = fav.created_at
	@twitter_url = 'https://twitter.com/_/status/' + fav.id.to_s

   
    comment = ref_comment("twitter_h", id)
    tag_c = tag_concat("twitter_h", id)
    tag_a = tag_a_concat("twitter_h", id)
    
    p @twitter_img_url 
      
    data_hash = {:app => "twitter_h", :twitter_img_url => @twitter_img_url, :twitter_user_name => @twitter_user_name, :twitter_screen_name => @twitter_screen_name, :twitter_text => @twitter_text, :twitter_time => @twitter_time, :tag_concat => tag_c, :tag_a_concat => tag_a, :id => new_id, :ref_count => ref_count, :comment => comment, :url => @twitter_url  }
  
    return data_hash

  end

  def twitter_favs_data_create(id)
  
    #p id

    ref_count = ref_counter("twitter_f", id)
    twit_id = Twitter_favorites.select(:data_id).filter(:id => id).first
    new_id = "twitter_f-" + id.to_s
    
    p twit_id.data_id
	 
    fav = @twitter.status(twit_id.data_id)
    
    @twitter_img_url = fav.user.profile_image_url 
    @twitter_user_name = fav.user.name
    @twitter_screen_name = fav.user.screen_name
    @twitter_text = fav.text
    @twitter_time = fav.created_at
	@twitter_url = 'https://twitter.com/_/status/' + fav.id.to_s
  
    comment = ref_comment("twitter_f", id)
    tag_c = tag_concat("twitter_f", id)
    tag_a = tag_a_concat("twitter_f", id) 
        
    data_hash = {:app => "twitter_f", :twitter_img_url => @twitter_img_url, :twitter_user_name => @twitter_user_name, :twitter_screen_name => @twitter_screen_name, :twitter_text => @twitter_text, :twitter_time => @twitter_time, :tag_concat => tag_c, :tag_a_concat => tag_a, :id => new_id, :ref_count => ref_count, :comment => comment , :url => @twitter_url }
   
    p @twitter_url
   
    return data_hash

  end
  
  def twitter_media_data_create(id)

    ref_count = ref_counter("twitter_m", id)
    
    media = Twitter_media.filter(:id => id)
    new_id = "twitter_m-" + id.to_s
    
    media.each do |elem|
     # p elem
      @twitter_media_url = elem.media_url
      @twitter_url = elem.url
      @twitter_issued = elem.issued
      @width = elem.width
      @height = elem.height
    end 
  
    comment = ref_comment("twitter_m", id)
    tag_c = tag_concat("twitter_m", id)
    tag_a = tag_a_concat("twitter_m", id) 
  
    data_hash = {:app => "twitter_m", :twitter_media_url => @twitter_media_url, :twitter_url => @twitter_url, :twitter_issued => @twitter_issued, :tag_concat => tag_c, :tag_a_concat => tag_a, :id => new_id, :ref_count => ref_count, :comment => comment, :width => @width.to_s, :height => @height.to_s }
  
    return data_hash
  
  
  end


  def twitter_url_data_create(id)

    ref_count = ref_counter("twitter_u", id)
    
    media = Twitter_urls.filter(:id => id)
    p media
    new_id = "twitter_u-" + id.to_s
    
    media.each do |elem|
      @twitter_title = elem.title
      @twitter_url = elem.url
      @twitter_issued = elem.issued
      @twitter_description = elem.description
      @twitter_default_url = 'https://twitter.com/_/status/' + elem.default.to_s
    end 
  
    comment = ref_comment("twitter_u", id)
    tag_c = tag_concat("twitter_u", id)
    tag_a = tag_a_concat("twitter_u", id) 
  
    data_hash = {:app => "twitter_u", :twitter_title => @twitter_title, :twitter_url => @twitter_url, :twitter_issued => @twitter_issued, :twitter_description => @twitter_description, :url => @twitter_url, :tag_concat => tag_c, :tag_a_concat => tag_a, :id => new_id, :ref_count => ref_count, :comment => comment, :default_url => @twitter_default_url }
  
    return data_hash

  end
  
  end
end

module TumblrData
  class TumblrData
  
  include AllData
  
  def initialize(uid,token, secret)
  
   @user_id = uid

   @conf = YAML.load_file("../config.yaml")
   
   Tumblife.configure do |config|
     config.consumer_key = @conf["tumblr_config"]["key"]
	 config.consumer_secret = @conf["tumblr_config"]["secret"]
	 config.oauth_token = token
	 config.oauth_token_secret = secret
   end
   
   @tumblr = Tumblife.client

  end

  def tumblr_data_create(id)

    ref_count = ref_counter("tumblr", id)
        
    blogurl = @tumblr.info.user.blogs[0].url
	p blogurl
    blogurl.gsub!('http://', '')
  
    post_id = Tumblr_posts.select(:data_id).filter(:id => id).first
    new_id = "tumblr-" + id.to_s    
  
    post = @tumblr.posts(blogurl, {:id => post_id.data_id}).posts[0]
  
    time = post.date    
    type = post.type
    tags = post.tag
	url = post.post_url
	
	p time
	p url
  
    comment = ref_comment("tumblr", id)
    tag_c = tag_concat("tumblr", id)
    tag_a = tag_a_concat("tumblr", id) 
    
    content = {:app => "tumblr", :id => new_id, :type => type, :tumblr_time => time, :tag_concat => tag_c,  :tag_a_concat => tag_a, :ref_count => ref_count, :comment => comment, :url => url }
    
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
  
  def tumblr_db_create()   
    
    info = @tumblr.info
    blogurl = info.user.blogs[0].url
    blogurl.gsub!('http://', '')
    
    offset = 0
    limit = 20
    
    begin
    
    catch(:tumblr_exit){
      begin
        res = @tumblr.posts(blogurl, {:offset => offset, :limit => limit})

        res.posts.each do |post|
          
          past_post = Tumblr_posts.select(:id).filter(:user_id => @user_id, :data_id => post.id).first
      
	      #p past_post
          if past_post
            throw :tumblr_exit
            
          else
            db_row_create(@user_id, "tumblr", post.id)
            
            post.tags.each do |tag|
              db_tag_create(@user_id,"tumblr", post.id, tag)                            
            end

          end
        
        end
        offset += limit      
      end while offset < res.total_posts
    }
    
    rescue
      p "error!"
    end

  end
  
  end
end

module InstagramData
  class InstagramData
  
  include AllData

  def initialize(uid,token)
  
    @user_id = uid

    @conf = YAML.load_file("../config.yaml")
  
    @instagram = Instagram.client(:access_token => token)

  end  

  def instagram_data_create(id)

    ref_count = ref_counter("instagram", id)
    photo_id = Instagram_photos.select(:data_id).filter(:id => id).first
    new_id = "instagram-" + id.to_s
  
    begin 
      photo = @instagram.media_item(photo_id.data_id)
      instagram_img_url = photo.images.low_resolution.url

      instagram_time = photo.created_time
      instagram_time = Time.at(instagram_time.to_i).to_s
	  url = photo.link
	  
	  p url
	
      if photo.caption
        instagram_tags = photo.tags #array  
        instagram_text = photo.caption.text
      else
        instagram_tags = nil
        instagram_text = nil
      end
  
      comment = ref_comment("instagram", id)
      tag_c = tag_concat("instagram", id)
      tag_a = tag_a_concat("instagram", id) 
      
      data_hash = {:app => "instagram", :instagram_img_url => instagram_img_url, :instagram_tags => instagram_tags, :instagram_time => instagram_time, :instagram_text => instagram_text, :tag_concat => tag_c, :tag_a_concat => tag_a, :id => new_id, :ref_count => ref_count, :comment => comment, :url => url  }
  
      return data_hash
  
    rescue
  
    end 
  end
  

  def instagram_db_create() 
    
    @instagram.user_recent_media.each do |photo|
    
      past_photo = Instagram_photos.select(:id).filter(:user_id => @user_id, :data_id => photo.id).first
      
      if past_photo
        break
      else
        
		db_row_create(@user_id,"instagram", photo.id)  
        
        if photo.tags #array
               
          photo.tags.each do |tag|   
            db_tag_create(@user_id,"instagram", photo.id, tag)            
          end            
        end
		
      end
    end
  
  end
  
  end  
end

module FlickrData
  class FlickrData
  
  include AllData

  
  def initialize(uid,token, secret)
  
    @user_id = uid

    @conf = YAML.load_file("../config.yaml")
	
	#Flickr.configure do |config|
    #  config.api_key = @conf["flickr_config"]["key"]
    #  config.shared_secret = @conf["flickr_config"]["secret"] 
    #end
    
    FlickRaw.api_key = @conf["flickr_config"]["key"]
    FlickRaw.shared_secret = @conf["flickr_config"]["secret"]
    flickr.access_token = token
    flickr.access_secret = secret
    
    @login = flickr.test.login
   # p user

    #@flickr = Flickr.new(token, secret)
    
  end
  
  def flickr_db_create()

    begin
    
      list = flickr.photos.search(:user_id => @login.id, :per_page => 500)

      list.each do |photo|
  
        past_photo = Flickr_photos.select(:id).filter(:user_id => @user_id, :data_id => photo.id).first

        if past_photo
		  break
        else
	      db_row_create(@user_id,"flickr", photo.id)  
        end   
      end
      
      if list.length > 0 && !session[:apps].index("flickr")
        session[:apps].push("flickr")      
      end
    
      fav_list = flickr.favorites.getList(:user_id => @login.id)
    
      fav_list.each do |photo|
  
        past_fphoto = Flickr_favorites.select(:id).filter(:user_id => @user_id, :data_id => photo.id).first

        if past_fphoto
		  break
        else
	      db_row_create(@user_id,"flickr_f", photo.id)  
        end   
      end   

      if fav_list.length > 0 && !session[:apps].index("flickr_f")
        session[:apps].push("flickr_f")      
      end
    
    rescue => e
 	  
 	  if e.message ==  "'flickr.photos.search' - Invalied API Key"
        reject("flickr")
        
      elsif e.message ==  "'flickr.favorites.getList' - Invalied API Key"
        reject("flickr")
      else
      end   
    
    end
    
  end

  def flickr_data_create(id)
	
    ref_count = ref_counter("flickr", id)
    photo_id = Flickr_photos.select(:data_id).filter(:id => id).first
    new_id = "flickr-" + id.to_s
  
    begin
      info = flickr.photos.getInfo(:photo_id => photo_id.data_id)
      
      sizes = flickr.photos.getSizes(:photo_id => photo_id.data_id)
      
      small_size = sizes.find{|s| s.label == "Small 320"}
      
	  url = 'http://www.flickr.com/photos/'+ @login.id + '/' + photo_id.data_id.to_s
    
      comment = ref_comment("flickr", id)
      tag_c = tag_concat("flickr", id)
      tag_a = tag_a_concat("flickr", id) 
      
      #p photo.title
        
      data_hash = {:app => "flickr", :flickr_img_url => small_size.source, :filickr_owner => info.owner.username, :flickr_time => info.dates.taken, :flickr_title => info.title, :flickr_text => info.description, :tag_concat => tag_c, :tag_a_concat => tag_a, :id => new_id, :ref_count => ref_count, :comment => comment , :url => url }

      return data_hash
    
    end

  end

  def flickr_favs_data_create(id)

	
    ref_count = ref_counter("flickr_f", id)
    photo_id = Flickr_favorites.select(:data_id).filter(:id => id).first
    
    p photo_id.data_id
    new_id = "flickr_f-" + id.to_s
  
    begin
      info = flickr.photos.getInfo(:photo_id => photo_id.data_id)
      
      sizes = flickr.photos.getSizes(:photo_id => photo_id.data_id)
      
      small_size = sizes.find{|s| s.label == "Small 320"}
      
      owner = info.owner.nsid
	  
	  p owner
	  
	  url = 'http://www.flickr.com/photos/'+ owner + '/' + photo_id.data_id.to_s
    
      comment = ref_comment("flickr_f", id)
      tag_c = tag_concat("flickr_f", id)
      tag_a = tag_a_concat("flickr_f", id) 
      
      #p photo.title
        
      data_hash = {:app => "flickr_f", :flickr_img_url => small_size.source,  :filickr_owner => info.owner.username,  :flickr_time => info.dates.taken, :flickr_title => info.title, :flickr_text => info.description, :tag_concat => tag_c, :tag_a_concat => tag_a, :id => new_id, :ref_count => ref_count, :comment => comment , :url => url }

      return data_hash
    
    end

  end
  
  end
end

module BrowserBookmarkData
  class BrowserBookmarkData
  
  include AllData
  
  def initialize(uid)
  
    @user_id = uid

  end  
  
  def browser_bookmarks_data_create(id)

    ref_count = ref_counter("browser_bookmarks", id)
    
    bookmark = Browser_bookmarks.filter(:id => id)
    new_id = "browser_bookmarks-" + id.to_s
    
    bookmark.each do |elem|
      @bb_title = elem.title
      @bb_url = elem.url
      @bb_issued = elem.issued
      @bb_description = elem.description
    end 
  
    comment = ref_comment("browser_bookmarks", id)
    tag_c = tag_concat("browser_bookmarks", id)
    tag_a = tag_a_concat("browser_bookmarks", id) 
  
    data_hash = {:app => "browser_bookmarks", :bb_title => @bb_title, :bb_url => @bb_url, :bb_issued => @bb_issued, :bb_description => @bb_description, :tag_concat => tag_c, :tag_a_concat => tag_a, :id => new_id, :ref_count => ref_count, :comment => comment }
  
    return data_hash

  end
  
  end
end

module HatenaData
  class HatenaData
  
  include AllData
  
  def initialize(uid)
    
    @user_id = uid
  
  end
  
  def hatena_data_create(id)

    ref_count = ref_counter("hatena", id)
    
    bookmark = Hatena_bookmarks.filter(:id => id)
    new_id = "hatena-" + id.to_s
    
    bookmark.each do |elem|
      @hatena_title = elem.title
      @hatena_url = elem.url
      @hatena_issued = elem.issued
    end 

    comment = ref_comment("hatena", id)
    tag_c = tag_concat("hatena", id)
    tag_a = tag_a_concat("hatena", id)     

    data_hash = {:app => "hatena", :hatena_title => @hatena_title, :hatena_url => @hatena_url, :hatena_issued => @hatena_issued, :tag_concat => tag_c, :tag_a_concat => tag_a, :id => new_id, :ref_count => ref_count, :comment => comment  }
  
    return data_hash

  end
  
  def hatena_db_create(token, secret)
  
    consumer = OAuth::Consumer.new(
      'CPplvRerEF3f5A==',
      'YtKTcjMlCfaOhVppKt0FNXVKZMI=',
      :site               => '',
      :request_token_path => 'https://www.hatena.com/oauth/initiate',
      :access_token_path  => 'https://www.hatena.com/oauth/token',
      :authorize_path     => 'https://www.hatena.ne.jp/oauth/authorize')	

    hatena = OAuth::AccessToken.new(consumer,token,secret)
    
    request_url = 'http://b.hatena.ne.jp/atom/feed?of=0' 
    
    begin
     
      catch(:hatena_exit){  
        while true
          response = hatena.request(:get, request_url)
  
          xml_doc = Nokogiri::XML(response.body)
          xml_doc.css("entry").each do |elem|
            entry_doc = Nokogiri::XML(elem.to_html)
            id = entry_doc.css("id")[0].content
        
            past_bookmark = Hatena_bookmarks.select(:id).filter(:user_id => @user_id, :id => id).first
        
            if past_bookmark
              throw :hatena_exit
                        
            else
              title = entry_doc.css("title")[0].content
              issued = entry_doc.css("issued")[0].content
              name = entry_doc.css("name")[0].content
              comment = entry_doc.css("summary")[0].content
              url = entry_doc.xpath("//*[@rel='related']")[0].attribute("href").value 
         
              entry_doc.xpath("//dc:subject", "dc" => 'http://purl.org/dc/elements/1.1/').each do |elem|
                db_tag_create("hatena", id, elem.content)
              end #--entry_coc.xpath().each
  
              Hatena_bookmarks.create({
                :user_id => @user_id,
                :data_id => id,
                :name => name,
                :title => title,
                :issued => issued,
                :url => url,
                :comment => comment,
                :refrection => 0,
                :shuffle => 0,
              })

            end #--if past_bookmark
       
            rel_next = xml_doc.xpath("//*[@rel='next']")[0]
          
            if rel_next
              request_url = xml_doc.xpath("//*[@rel='next']")[0].attribute("href").value
            else
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
   
  end
end

module EvernoteData
  class EvernoteData
  
  include AllData

  def initialize(uid)
    
    @user_id = uid
    @evernote_oauth = Evernote_oauth.where(:uid => @user_id).first
  
  end

  def evernote_data_create(id)

    ref_count = ref_counter("evernote", id)
	  
    noteStoreUrl = NOTESTORE_URL_BASE + @evernote_oauth.evernote_shard_id
    noteStoreTransport = Thrift::HTTPClientTransport.new(noteStoreUrl)
    noteStoreProtocol = Thrift::BinaryProtocol.new(noteStoreTransport)
    noteStore = Evernote::EDAM::NoteStore::NoteStore::Client.new(noteStoreProtocol)  
  
    guid = Evernote_notes.select(:data_id).filter(:id => id).first
    new_id = "evernote-" + id.to_s
  
    note = noteStore.getNote(@evernote_oauth.evernote_access_token, guid.data_id ,true,true,true,true)
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

    comment = ref_comment("evernote", id)
    tag_c = tag_concat("evernote", id)
    tag_a = tag_a_concat("evernote", id)     

    data_hash = {:app => "evernote", :note_title => @note_title, :content => @content, :snippet => @snippet, :link => @link, :tag_concat => tag_c, :tag_a_concat => tag_a, :id => new_id, :ref_count => ref_count, :evernote_time => @create_time, :comment => comment  }
  
    return data_hash

  end 
  
  def evernote_db_create()

    noteStoreUrl = NOTESTORE_URL_BASE + @evernote_oauth.evernote_shard_id
    noteStoreTransport = Thrift::HTTPClientTransport.new(noteStoreUrl)
    noteStoreProtocol = Thrift::BinaryProtocol.new(noteStoreTransport)
    noteStore = Evernote::EDAM::NoteStore::NoteStore::Client.new(noteStoreProtocol)
    
    notebooks = noteStore.listNotebooks(@evernote_oauth.evernote_access_token)
      
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
          res = noteStore.findNotesMetadata(@evernote_oauth.evernote_access_token, filter, offset, 10, spec)
      
          i = res.notes.length
          while i > 0 
      
            i = i - 1      
            past_note = Evernote_notes.select(:id).filter(:user_id => @user_id, :data_id => res.notes[i].guid).first
      
            if past_note
			  throw :evernote_exit
			else
			   db_row_create(@user_id,"evernote", res.notes[i].guid)
       
              evernote_tags = res.notes[i].tagGuids
              if evernote_tags
                
                evernote_tags.each do |tag_id|
                  tag_resource = noteStore.getTag(@evernote_oauth.evernote_access_token, tag_id)
                  tag = tag_resource.name.force_encoding("UTF-8")
                  db_tag_create(@user_id,"evernote", res.notes[i].guid, tag)

                end  #-- evernote_tags.each
              end #--if evernote_tags
          

            end #-- if past_note.empty?          
       
          end #-- while
    
          offset = offset + pageSize
    
        end while res.totalNotes > offset
    
      } #-- catch
    
    rescue Evernote::EDAM::Error::EDAMUserException => e
	  #再認証が必要
	  if e.errorCode == 9
	    AllData.reject(@user_id, "evernote")
      end

    end

  end
 
  end
end


module RssData
  class RssData
  
  include AllData
  
  def initialize(uid)
    
    @user_id = uid
      
  end

  def rss_data_create(id)

    ref_count = ref_counter("rss", id)
    
    item = Rss_item.filter(:data_id => id)
  
    new_id = "rss-" + id.to_s
    
    item.each do |elem|
      @rss_title = elem.title
      @rss_url = elem.url
      @rss_date = elem.date
      @rss_description = elem.description
    end 
  
    comment = ref_comment("rss", id)
    tag_c = tag_concat("rss", id)
    tag_a = tag_a_concat("rss", id) 
               
    data_hash = {:app => "rss", :rss_title => @rss_title, :rss_url => @rss_url, :rss_date => @rss_date, :rss_description => @rss_description, :tag_concat => tag_c, :tag_a_concat => tag_a, :id => new_id, :ref_count => ref_count, :comment => comment  }
  
    return data_hash

  end

  def rss_db_create(e, channel_id)
    past_item = Rss_item.select(:id).filter(:url => e.url).first
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
     
    this_data = Rss_item.select(:id).filter(:url => e.url).first

    past_relate_id = Rss_user_relate.select(:id).filter(:user_id => @user_id, :id => this_data.id).first
     
    unless past_relate_id
      #p this_data.data_id
      Rss_user_relate.create({
        :user_id => @user_id,
        :id => this_data.id,
        :refrection => 0,
        :channel_id => channel_id,
        :shuffle => 0,
      })
    end
  end
  
  end
end



