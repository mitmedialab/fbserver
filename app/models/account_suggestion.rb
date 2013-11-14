# -*- encoding : utf-8 -*-
require 'json'
class AccountSuggestion < ActiveRecord::Base
  belongs_to :account

  def users
    return [] if self.suggesters.nil?
    JSON.parse(self.suggesters).collect{|i| i.to_i}
  end

  def add_user user
    all_users = self.users
    if !all_users.include? user.uid
      all_users << user.uid
      self.suggesters = all_users.to_json
      self.save
    end
  end

  def remove_user user
    ## UTILITY METHOD ONLY TO BE CALLED BY User.unsuggest_account
    ## error if the account exists in the user
    return nil if user.all_suggested_accounts.include? self.account.uuid

    all_users = self.users
    
    all_users.delete user.uid.to_i
    self.suggesters = all_users.to_json
    self.save
    return true
  end

end
