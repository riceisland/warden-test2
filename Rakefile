require "bundler/setup"
Bundler.require(:default)
require "resque/tasks"
require "./app2"
require "./job"

task "resque:setup" do
    ENV['QUEUE'] = '*'
    
    #このへんにデーモン
    
end

task "jobs:work" => "resque:work"