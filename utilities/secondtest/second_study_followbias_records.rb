require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment.rb')



puts "user.id,user.group,user.screen_name, user.gender, followbias_records, friendsrecords, ffb.date, ffr.date,lfb.date,lfr.date,efb.date,efr.date,nfb.date,nfr.date,ofb.date,ofr.date"
#user.total_actions, user.login_date, user.total_followbias_records,ffb.date, ffb.male, ffb.female, ffb.unknown, lfb.date, lfb.male, lfb.female, lfb.unknown, 1fb.date, 1fb.male, 1fb.female, 1fb.unknown, 2fb.date, 2fb.male, 2fb.female, 2fb.unknown, 3fb.date, 3fb.male, 3fb.female, 3fb.unknown, post_survey,satisfied_with_followbias,will_it_influence,how_change,percent_women_goal"

User.where("(treatment='test' OR treatment='ctl') AND twitter_token IS NOT NULL and survey_complete=true ").each do |user|
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
    efb = user.followbias_records.order(:created_at).where("created_at >= '#{login_date + 1.week}' AND created_at <='#{login_date + 2.week}'").first
    nfb = user.followbias_records.order(:created_at).where("created_at >= '#{login_date + 2.week}' AND created_at <='#{login_date + 3.week}'").first
    ofb = user.followbias_records.order(:created_at).where("created_at >= '#{login_date + 3.week}'").first
    efb_created_at = ffb_created_at = lfb_created_at = nfb_created_at = ofb_created_at =  nil

    ffb_created_at = ffb.created_at if ffb
    lfb_created_at = lfb.created_at if lfb
    efb_created_at = efb.created_at if efb
    nfb_created_at = nfb.created_at if nfb
    ofb_created_at = ofb.created_at if ofb

    ffr = user.friendsrecords.order(:created_at)[0]
    lfr = user.friendsrecords.order(:created_at).where("created_at <= '#{login_date}'").last
    efr = user.friendsrecords.order(:created_at).where("created_at >= '#{login_date + 1.week}' AND created_at <='#{login_date + 2.week}' AND incomplete IS FALSE").first
    nfr = user.friendsrecords.order(:created_at).where("created_at >= '#{login_date + 2.week}' AND created_at <='#{login_date + 3.week}' AND incomplete IS FALSE").first
    ofr = user.friendsrecords.order(:created_at).where("created_at >= '#{login_date + 3.week}' AND incomplete IS FALSE").first

    ffr_created_at = ffr.created_at if ffr
    lfr_created_at = lfr.created_at if lfr
    efr_created_at = efr.created_at if efr
    nfr_created_at = nfr.created_at if nfr
    ofr_created_at = ofr.created_at if ofr

    puts [user.id, user.treatment, user.screen_name, gender, user.followbias_records.size,user.friendsrecords.size,
          login_date,
          ffb_created_at, ffr_created_at,
          lfb_created_at, lfr_created_at,
          efb_created_at, efr_created_at,
          nfb_created_at, nfr_created_at,
          ofb_created_at, ofr_created_at
    ].join(",")
  end
end

