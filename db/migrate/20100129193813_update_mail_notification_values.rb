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

# Patch the data from a boolean change.
class UpdateMailNotificationValues < ActiveRecord::Migration
  def self.up
    # No-op
    # See 20100129193402_change_users_mail_notification_to_string.rb
  end

  def self.down
    # No-op
  end
end
