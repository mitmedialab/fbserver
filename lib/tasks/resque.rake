require "resque/tasks"
require "resque_scheduler/tasks"

task "resque:setup" do
  require 'resque'
  require 'resque_scheduler'

  raise "Please set your RESQUE_WORKER variable to true" unless ENV['RESQUE_WORKER'] == "true"

  root_path = "#{File.dirname(__FILE__)}/../.."
  require "#{root_path}/app/workers/workers.rb"

  Resque.schedule = YAML.load_file "#{root_path}/config/resque_schedule.yml"

end
