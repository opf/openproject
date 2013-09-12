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

def become_admin
  let(:current_user) { FactoryGirl.create(:admin) }
end

def become_non_member(&block)
  let(:current_user) { FactoryGirl.create(:user) }

  before do
    projects = block ? instance_eval(&block) : [project]

    projects.each do |p|
      current_user.memberships.select {|m| m.project_id == p.id}.each(&:destroy)
    end
  end
end

def become_member_with_permissions(permissions)
  let(:current_user) { FactoryGirl.create(:user) }

  before do
    role = FactoryGirl.create(:role, :permissions => permissions)

    member = FactoryGirl.build(:member, :user => current_user, :project => project)
    member.roles = [role]
    member.save!
  end
end

def become_member_with_view_planning_element_permissions
  become_member_with_permissions [:view_planning_elements, :view_work_packages]
end

def become_member_with_move_work_package_permissions
  become_member_with_permissions [:move_work_packages]
end
