#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class Token < ActiveRecord::Base
  belongs_to :user
  validates_uniqueness_of :value
  
  #attr_protected :user_id

  before_create :delete_previous_tokens
  before_create :assign_generated_token

  @@validity_time = 1.day

  # Return true if token has expired
  def expired?
    return Time.now > self.created_on + @@validity_time
  end

  # Delete all expired tokens
  def self.destroy_expired
    Token.delete_all ["action <> 'feeds' AND created_on < ?", Time.now - @@validity_time]
  end

private

  def self.generate_token_value
    SecureRandom.hex(20)
  end

  # Removes obsolete tokens (same user and action)
  def delete_previous_tokens
    if user
      Token.delete_all(['user_id = ? AND action = ?', user.id, action])
    end
  end

  def assign_generated_token
    self.value = self.class.generate_token_value
  end
end
