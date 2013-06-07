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

class SetDocAndFilesNotifications < ActiveRecord::Migration
  # model removed
  class Permission < ActiveRecord::Base; end

  def self.up
    Permission.find_by_controller_and_action("projects", "add_file").update_attribute(:mail_option, true)
    Permission.find_by_controller_and_action("projects", "add_document").update_attribute(:mail_option, true)
    Permission.find_by_controller_and_action("documents", "add_attachment").update_attribute(:mail_option, true)
    Permission.find_by_controller_and_action("issues", "add_attachment").update_attribute(:mail_option, true)
  end

  def self.down
    Permission.find_by_controller_and_action("projects", "add_file").update_attribute(:mail_option, false)
    Permission.find_by_controller_and_action("projects", "add_document").update_attribute(:mail_option, false)
    Permission.find_by_controller_and_action("documents", "add_attachment").update_attribute(:mail_option, false)
    Permission.find_by_controller_and_action("issues", "add_attachment").update_attribute(:mail_option, false)
  end
end
