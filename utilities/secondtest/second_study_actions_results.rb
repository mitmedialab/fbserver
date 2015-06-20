require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment.rb')


users_clicked_suggestions = users_made_suggestions = users_made_corrections = users_reloaded_suggestions = users_clicked_corrections = 0


puts "user.id,user.group,user.screen_name, user.gender, user.total_actions, user.suggestion_views, user.suggestion_page_reload, user.correction_views, user.suggestions, user.corrections"

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

    total_suggestion_views = user.activity_logs.where("action='clicked_suggestions_screen_name'").size
    total_correction_views = user.activity_logs.where("action='clicked_corrections_screen_name'").size
    total_suggestion_page_reload = user.activity_logs.where("action='reloaded_suggestions'").size
    total_suggestions = user.activity_logs.where("action='followbias/toggle_suggest'").size
    total_corrections = user.activity_logs.where("action='followbias/correct'").size

    users_clicked_suggestions += 1 if total_suggestion_views > 0 
    users_clicked_corrections += 1 if total_correction_views > 0 
    users_made_suggestions +=1 if total_suggestions > 0
    users_made_corrections += 1 if total_corrections > 0
    users_reloaded_suggestions +=1 if total_suggestion_page_reload > 0 

    # user id, login date, total actions, 
    # first followbias date, ffb male, ffb female, ffb unknown,
    # login followbias date, lfb male, lfb female, lfb unknown
    # end followbias date, efb male, efb female, efb unknown
    puts [user.id, user.treatment, user.screen_name, gender, total_actions,
          total_suggestion_views, total_suggestion_page_reload, total_correction_views, total_suggestions, total_corrections
    ].join(",")
  end
end


puts "========================="
puts "Total Users: #{User.where('treatment="test" AND survey_complete=true').size}"
puts "Clicked suggestions: #{users_clicked_suggestions}"
puts "Made suggestions: #{users_made_suggestions}"
puts "Reloaded Suggestions: #{users_reloaded_suggestions}"
puts "Made Corrections: #{users_made_corrections}"
puts "Clicked Corrections: #{users_clicked_corrections}"
