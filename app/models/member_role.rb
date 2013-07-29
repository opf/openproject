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

class MemberRole < ActiveRecord::Base
  belongs_to :member
  belongs_to :role

  after_create :add_role_to_group_users
  after_destroy :remove_role_from_group_users

  attr_protected :member_id, :role_id

  validates_presence_of :role
  validate :validate_project_member_role

  def validate_project_member_role
    errors.add :role_id, :invalid if role && !role.member?
  end

  # Add alias, so Member can still destroy MemberRoles
  # Don't call this from anywhere else, use remove_member_role on Member.
  alias :destroy_for_member :destroy

  # You shouldn't call this, only ActiveRecord itself is allowed to do this
  # when destroying a Member. Use Member.remove_member_role to remove a role from a member.
  #
  # You may remove this once we have a layer above persistence that handles business logic
  # and prevents or at least discourages working on persistence objects from controllers
  # or unrelated business logic.
  def destroy(*args)
    unless caller.first =~ /has_many_association\.rb:[0-9]+:in `[^`]+delete_records'/
      raise 'MemberRole.destroy called from method other than HasManyAssociation.delete_records' +
            "\n  on #{inspect}\n from #{caller.first} / #{caller[3]}"
    else
      super
    end
  end

  def inherited?
    !inherited_from.nil?
  end

  private

  def add_role_to_group_users
    if member && member.principal.is_a?(Group)
      member.principal.users.each do |user|
        user_member = Member.find_by_project_id_and_user_id(member.project_id, user.id)

        if user_member.nil?
          user_member = Member.new.tap do |m|
            m.project_id = member.project_id
            m.user_id = user.id
          end

          user_member.member_roles << MemberRole.new(:role => role, :inherited_from => id)

          user_member.save
        else
          user_member.member_roles << MemberRole.new(:role => role, :inherited_from => id)
        end
      end
    end
  end

  def remove_role_from_group_users
    MemberRole.all(:conditions => { :inherited_from => id }).group_by(&:member).each do |member, member_roles|
      member_roles.each { |mr| member.remove_member_role!(mr) }
      if member && member.user
        Watcher.prune(:user => member.user, :project => member.project)
      end
    end
  end
end
