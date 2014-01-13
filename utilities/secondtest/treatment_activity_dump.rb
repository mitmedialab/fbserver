require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment.rb')

#TODO: Add in total activities and other things

puts "user_id, gender, login_date, total_actions, total_followbias_records,first followbias date, ffb male, ffb female, ffb unknown, login followbias date, lfb male, lfb female, lfb unknown, end followbias date, efb male, efb female, efb unknow"

User.where("treatment='test' AND twitter_token IS NOT NULL").each do |user|
  # verify that they took the survey and returned to the site
  login = user.activity_logs.where("action='pre_survey_complete'")
  if(login.size>0 and user.followbias_records.size > 0 )
    id = user.id
    login_date = login[0].created_at
    total_actions = user.activity_logs.size
    total_followbias = user.followbias_records.size
    gender = "Unknown"
    a = Account.find_by_uuid(user.uid.to_i)
    gender = a.gender if a
    ffb = user.followbias_records.order(:created_at)[0]
    lfb = user.followbias_records.order(:created_at).where("created_at <= '#{login_date}'").last
    efb = user.followbias_records.order(:created_at).where("created_at >= '#{login_date + 1.week}'").first
    if efb
      efb_created_at = efb.created_at
      efb_male = efb.male
      efb_female = efb.female
      efb_unknown = efb.unknown
    else
      efb_created = efb_male = efb_female = efb_unknown = nil
    end
    # user id, login date, total actions, 
    # first followbias date, ffb male, ffb female, ffb unknown,
    # login followbias date, lfb male, lfb female, lfb unknown
    # end followbias date, efb male, efb female, efb unknown
    puts [user.id, user.screen_name, gender, login_date, user.screen_name, total_actions, total_followbias,
          ffb.created_at, ffb.male, ffb.female, ffb.unknown,
          lfb.created_at, lfb.male, lfb.female, lfb.unknown,
          efb_created_at, efb_male, efb_female, efb_unknown
    ].join(",")
  end
end

