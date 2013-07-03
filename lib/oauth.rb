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

module Oauth

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

module_function :configure_twitter_token
module_function :configure_tumblr_token
module_function :base_url
module_function :twitter_oauth_consumer
module_function :tumblr_oauth_consumer
module_function :hatena_oauth_consumer
module_function :evernote_oauth_consumer


end