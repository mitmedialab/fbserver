require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment.rb')
require 'digest/sha1'

puts "user.id,user.group,user.screen_name, user.gender, user.total_actions, user.total_suggestion_views, user.correction_views, user.suggestion_page_reload, user.suggestions, user.corrections, user.login_date, user.total_followbias_records,ffb.date, ffb.male, ffb.female, ffb.unknown, lfb.date, lfb.male, lfb.female, lfb.unknown, 1fb.date, 1fb.male, 1fb.female, 1fb.unknown, 2fb.date, 2fb.male, 2fb.female, 2fb.unknown, 3fb.date, 3fb.male, 3fb.female, 3fb.unknown, post_survey,satisfied_with_followbias,will_it_influence,how_change,percent_women_goal,survey_id"

User.where("(treatment='test' OR treatment='ctl') AND twitter_token IS NOT NULL").each do |user|
  # verify that they took the survey and returned to the site
  login = user.activity_logs.where("action='pre_survey_complete'")
  if(user.friendsrecords.size > 0 )
    id = user.id
    if(login.size>0)
      login_date = login[0].created_at
    else
      login_record = user.friendsrecords.order(:created_at).where("created_at >= '#{Date.parse("2013-12-20")}'").first
      login_date = login_record.created_at
    end
    total_actions = user.activity_logs.size
    total_followbias = user.followbias_records.size
    gender = "Unknown"
    a = Account.find_by_uuid(user.uid.to_i)
    gender = a.gender if a

    total_suggestion_views = user.activity_logs.where("action='clicked_suggestions_screen_name'").size
    total_correction_views = user.activity_logs.where("action='clicked_corrections_screen_name'").size
    total_suggestion_page_reload = user.activity_logs.where("action='reloaded_suggestions'").size
    total_suggestions = user.activity_logs.where("action='followbias/toggle_suggest'").size
    total_corrections = user.activity_logs.where("action='followbias/correct'").size

    ffr = user.friendsrecords.order(:created_at)[0]
    lfr = user.friendsrecords.order(:created_at).where("created_at <= '#{login_date}'").last
    efr = user.friendsrecords.order(:created_at).where("created_at >= '#{login_date + 1.week}' AND created_at <='#{login_date + 2.week}' AND incomplete IS FALSE").first
    nfr = user.friendsrecords.order(:created_at).where("created_at >= '#{login_date + 2.week}' AND created_at <='#{login_date + 3.week}' AND incomplete IS FALSE").first
    ofr = user.friendsrecords.order(:created_at).where("created_at >= '#{login_date + 3.week}' AND incomplete IS FALSE").first

    efb_created_at = ffr_created_at = lfr_created_at = nfr_created_at = ofr_created_at =  nil

    ffb_created_at = ffr.created_at if ffr
    lfb_created_at = lfr.created_at if lfr
    efb_created_at = efr.created_at if efr
    nfb_created_at = nfr.created_at if nfr
    ofb_created_at = ofr.created_at if ofr

    ffb = user.followbias_for_record(ffr, false)
    lfb = user.followbias_for_record(lfr, false)
    efb = user.followbias_for_record(efr, false)
    nfb = user.followbias_for_record(nfr, false)
    ofb = user.followbias_for_record(ofr, false)

    #ffb = user.followbias_records.order(:created_at)[0]
    #lfb = user.followbias_records.order(:created_at).where("created_at <= '#{login_date}'").last
    #efb = user.followbias_records.order(:created_at).where("created_at >= '#{login_date + 1.week}' AND created_at <='#{login_date + 2.week}'").first
    #nfb = user.followbias_records.order(:created_at).where("created_at >= '#{login_date + 2.week}' AND created_at <='#{login_date + 3.week}'").first
    #ofb = user.followbias_records.order(:created_at).where("created_at >= '#{login_date + 3.week}'").first
    if ffb
      ffb_male = ffb[:male]
      ffb_female = ffb[:female]
      ffb_unknown = ffb[:unknown]
    else
      ffb_male = ffb_female = ffb_unknown = nil
    end
    if lfb
      lfb_male = lfb[:male]
      lfb_female = lfb[:female]
      lfb_unknown = lfb[:unknown]
    else
      lfb_male = lfb_female = lfb_unknown = nil
    end
    if efb
      efb_male = efb[:male]
      efb_female = efb[:female]
      efb_unknown = efb[:unknown]
    else
      efb_male = efb_female = efb_unknown = nil
    end
    if nfb
      nfb_male = nfb[:male]
      nfb_female = nfb[:female]
      nfb_unknown = nfb[:unknown]
    else
      nfb_male = nfb_female = nfb_unknown = nil
    end
    if ofb
      ofb_male = ofb[:male]
      ofb_female = ofb[:female]
      ofb_unknown = ofb[:unknown]
    else
      ofb_male = ofb_female = ofb_unknown = nil
    end

    post_survey = JSON.load(user.post_survey)
    satisfied_with_followbias = will_it_influence = how_change = percent_women_goal = nil
    satisfied_with_followbias = (post_survey["satisfied_with_followbias"] == "Y") if post_survey
    will_it_influence = (post_survey["will_it_influence"] == "Y") if post_survey
    how_change = post_survey["change"] if post_survey
    percent_women_goal = post_survey["percent_women_goal"] if post_survey

    treatment = user.treatment 
    treatment="outside" if !user.survey_complete

    # user id, login date, total actions, 
    # first followbias date, ffb male, ffb female, ffb unknown,
    # login followbias date, lfb male, lfb female, lfb unknown
    # end followbias date, efb male, efb female, efb unknown
    puts [user.id, treatment, user.screen_name, gender, total_actions, 
          total_suggestion_views, total_correction_views, total_suggestion_page_reload, total_suggestions, total_corrections,
          login_date, total_followbias,
          ffb_created_at, ffb_male, ffb_female, ffb_unknown,
          lfb_created_at, lfb_male, lfb_female, lfb_unknown,
          efb_created_at, efb_male, efb_female, efb_unknown,
          nfb_created_at, nfb_male, nfb_female, nfb_unknown,
          ofb_created_at, ofb_male, ofb_female, ofb_unknown,
          !post_survey.nil?, satisfied_with_followbias, will_it_influence, 
          how_change, percent_women_goal,  Digest::SHA1.hexdigest(user.screen_name)
    ].join(",")
  end
end

