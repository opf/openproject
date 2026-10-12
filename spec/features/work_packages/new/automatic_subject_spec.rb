# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe "new work package with automatic subject type", :js, :selenium do
  let!(:type) { create(:type, :with_subject_pattern) }
  let!(:status) { create(:status, is_default: true) }
  let!(:priority) { create(:priority, is_default: true) }
  let!(:project) do
    create(:project, types: [type], no_types: true)
  end

  let(:subject_field) { wp_page.edit_field :subject }
  let(:wp_page) { Pages::FullWorkPackageCreate.new(project:) }

  current_user { create(:user, member_with_permissions: { project => %i[view_work_packages add_work_packages] }) }

  it "automatically fills the subject field with the pattern on creation" do
    wp_page.visit!
    subject_field.expect_state_text "Automatically generated through type #{type.name}"

    wp_page.save!

    wp_page.expect_toast message: "Successful creation."

    work_package = WorkPackage.last

    subject_field.expect_display_value "#{current_user.name} - #{status.name}/#{type.name} - #{work_package.id}"
  end
end
