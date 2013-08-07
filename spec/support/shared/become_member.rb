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

module BecomeMember
  def self.included(base)
    base.send(:include, InstanceMethods)
  end

  module InstanceMethods
    def become_member_with_permissions(project, user, permissions = [])
      permissions = Array(permissions)

      role = FactoryGirl.create(:role, :permissions => permissions)

      member = FactoryGirl.build(:member, :user => user, :project => project)
      member.roles = [role]
      member.save!
    end
  end
end
