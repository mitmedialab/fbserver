Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, '4FSppuZFL1fVoEEoppv2zQ', 'VocfRmMaIzCjSk5g3QYM1MuZRtaYHk0DGO6aMvGgoE'
end

ENV['TWITTER_CONSUMER_KEY'] = '4FSppuZFL1fVoEEoppv2zQ'
ENV['TWITTER_CONSUMER_SECRET'] = 'VocfRmMaIzCjSk5g3QYM1MuZRtaYHk0DGO6aMvGgoE'
#Twitter.configure do |config|
#  config.consumer_key = "4FSppuZFL1fVoEEoppv2zQ",
#  config.consumer_secret = "VocfRmMaIzCjSk5g3QYM1MuZRtaYHk0DGO6aMvGgoE"
#end
