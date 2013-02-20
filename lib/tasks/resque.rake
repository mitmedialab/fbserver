require "resque/tasks"

task "resque:setup" do
  raise "Please set your RESQUE_WORKER variable to true" unless ENV['RESQUE_WORKER'] == "true"
  root_path = "#{File.dirname(__FILE__)}/../.."
  require "#{root_path}/app/workers/workers.rb"
end
