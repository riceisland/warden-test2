require "bundler/setup"
Bundler.require(:default)
require "resque/tasks"
require "./app2"
require "./job"

task "resque:setup" do
    ENV['QUEUE'] = '*'
    
    #‚±‚Ì‚Ö‚ñ‚Éƒf[ƒ‚ƒ“
    
      log_file = ENV['RESQUE_LOG_PATH']
  Resque.logger = Logger.new(log_file) unless log_file.nil?
  Resque.logger.level = Logger::DEBUG
    
end

task "jobs:work" => "resque:work"