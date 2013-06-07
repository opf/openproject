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

# Create memberships like this:
#
#   project = FactoryGirl.create(:project)
#   user    = FactoryGirl.create(:user)
#   role    = FactoryGirl.create(:role, :permissions => [:view_wiki_pages, :edit_wiki_pages])
#
#   member = FactoryGirl.create(:member, :user => user, :project => project)
#   member.role_ids = [role.id]
#   member.save!
#
# It looks like you cannot create member_role models directly.

FactoryGirl.define do
  factory :member do
    user
    project
  end
end
