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

class PopulateMemberRoles < ActiveRecord::Migration
  def self.up
    MemberRole.delete_all
    Member.find(:all).each do |member|
      MemberRole.create!(:member_id => member.id, :role_id => member.role_id)
    end
  end

  def self.down
    MemberRole.delete_all
  end
end
