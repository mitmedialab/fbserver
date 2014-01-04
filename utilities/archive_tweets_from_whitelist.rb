require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')
require File.join(File.dirname(__FILE__), '..', 'app', 'workers', 'workers.rb')
require 'csv'
require 'resque'
require 'resque-lock-timeout'


# requires workers on followbias_jobs_ENV
# USAGE: archive_tweets_from_whitelist <WHITELIST> <OUTDIR>

class ArchiveTweetsFromUserAccounts
  include CatchTwitterRateLimit
  @queue = "followbias_jobs_#{Rails.env}".to_sym
  def self.perform task
  end
end

whitelist = CSV.read(ARGV[0])
whitelist.each do |row|
  screen_name = row[0]
  Resque.enqueue(ArchiveTweetsFromUserAccounts, {:account=>screen_name, :dir=>ARGV[1]})
end
