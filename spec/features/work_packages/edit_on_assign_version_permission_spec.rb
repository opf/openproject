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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require "features/page_objects/notification"

RSpec.describe "edit work package", :js, with_settings: { work_package_multiple_versions: false } do
  let(:current_user) do
    create(:user,
           firstname: "Dev",
           lastname: "Guy",
           member_with_permissions: { project => permissions })
  end
  let(:permissions) { %i[view_work_packages assign_versions] }

  let(:cf_all) do
    create(:work_package_custom_field, is_for_all: true, field_format: "text")
  end

  let(:type) { create(:type, custom_fields: [cf_all]) }
  let(:project) { create(:project, types: [type]) }
  let(:work_package) do
    create(:work_package,
           author: current_user,
           project:,
           type:,
           created_at: 5.days.ago.to_date.to_fs(:db))
  end
  let(:status) { work_package.status }

  let(:wp_page) { Pages::FullWorkPackage.new(work_package) }
  let(:version) { create(:version, project:) }

  def visit!
    wp_page.visit!
    wp_page.ensure_page_loaded
  end

  before do
    login_as(current_user)

    visit!
  end

  context "as a user having only the assign_versions permission" do
    it "can only change the version" do
      wp_page.fill_in_attributes targetVersions: version.name

      wp_page.expect_toast(message: "Successful update")
      wp_page.expect_attributes targetVersions: version.name

      subject_field = wp_page.work_package_field("subject")
      subject_field.expect_read_only
    end
  end

  context "as a user having only the edit_work_packages permission" do
    let(:permissions) { %i[view_work_packages edit_work_packages] }

    it "can not change the version" do
      version_field = wp_page.work_package_field("targetVersions")
      version_field.expect_read_only
    end
  end
end
