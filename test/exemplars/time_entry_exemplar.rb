#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class TimeEntry < ActiveRecord::Base
  generator_for(:spent_on) { Date.today }
  generator_for(:hours) { (rand * 10).round(2) } # 0.01 to 9.99
  generator_for :user, :method => :generate_user

  def self.generate_user
    User.generate_with_protected!
  end

end
