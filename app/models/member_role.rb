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

class MemberRole < ActiveRecord::Base
  belongs_to :member
  belongs_to :role

  after_destroy :remove_member_if_empty

  after_create :add_role_to_group_users
  after_destroy :remove_role_from_group_users

  validates_presence_of :role

  def validate
    errors.add :role_id, :invalid if role && !role.member?
  end

  def inherited?
    !inherited_from.nil?
  end

  private

  def remove_member_if_empty
    if member.roles.empty?
      member.destroy
    end
  end

  def add_role_to_group_users
    if member.principal.is_a?(Group)
      member.principal.users.each do |user|
        user_member = Member.find_by_project_id_and_user_id(member.project_id, user.id) || Member.new(:project_id => member.project_id, :user_id => user.id)
        user_member.member_roles << MemberRole.new(:role => role, :inherited_from => id)
        user_member.save!
      end
    end
  end

  def remove_role_from_group_users
    MemberRole.find(:all, :conditions => { :inherited_from => id }).group_by(&:member).each do |member, member_roles|
      member_roles.each(&:destroy)
      if member && member.user
        Watcher.prune(:user => member.user, :project => member.project)
      end
    end
  end
end
