# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Fbserver::Application.initialize!

# This setting defines the maximum number of friends
# Allowed on FollowBias. The workers will return empty
# And the experimental sample will exclude any users
# that have more than this number of friends
# Currently set to the 99th percentile of the journalist dataset
MAX_FRIENDS = 4521
