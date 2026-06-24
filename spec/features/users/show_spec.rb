# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "index users", :js do
  shared_let(:user) { create(:admin) }
  shared_let(:other_user) { create(:user) }

  current_user { user }

  shared_let(:group) do
    create(:group, lastname: "A-Team", members: [user])
  end

  let(:index_page) { Pages::Admin::Users::Index.new }

  it "displays the user's projects, groups and activity list", with_settings: { journal_aggregation_time_minutes: 0 } do
    # create some activities
    project = create(:project_with_types)
    project.update(name: "new name", description: "new project description")

    work_package = create(:work_package, author: user, project:)
    work_package.update(subject: "new subject", description: "new work package description")

    visit user_path(user)

    expect(page).to have_text("Project: #{project.name}")
    expected_work_package_title = "#{work_package.type.name} ##{work_package.id}: #{work_package.subject} " \
                                  "(Project: #{work_package.project.name})"
    expect(page).to have_text(expected_work_package_title)

    # Expect group visible
    expect(page).to have_text(group.name)
  end

  context "as another user" do
    current_user { other_user }

    it "does not show the group" do
      visit user_path(user)
      expect(page).to have_no_text group.name
    end
  end

  describe "built-in and custom field attributes in the side panel" do
    shared_let(:section) { create(:user_custom_field_section, name: "Public profile") }
    shared_let(:custom_field) do
      create(:user_custom_field, :string, name: "Job title", user_custom_field_section: section)
    end
    shared_let(:profile_user) do
      create(:user, firstname: "Sarah", mail: "s.chen@example.com",
                    custom_values: [build(:custom_value, custom_field:, value: "Developer")])
    end

    before do
      section.update_column(:attribute_order, ["firstname", "mail", custom_field.column_name])
      visit user_path(profile_user)
    end

    it "shows built-in attributes alongside custom fields" do
      expect(page).to have_text(User.human_attribute_name("firstname"))
      expect(page).to have_text("Sarah")
      expect(page).to have_text("s.chen@example.com")
      expect(page).to have_text("Job title")
      expect(page).to have_text("Developer")
    end
  end
end
