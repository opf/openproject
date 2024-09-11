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
require "support/pages/custom_fields"

RSpec.describe "custom fields", :js, :with_cuprite do
  let(:user) { create(:admin) }
  let(:cf_page) { Pages::CustomFields.new }
  let(:for_all_cf) { create(:list_wp_custom_field, is_for_all: true) }
  let(:project_specific_cf) { create(:integer_wp_custom_field) }
  let(:work_package) do
    wp = build(:work_package).tap do |wp|
      wp.type.custom_fields = [for_all_cf, project_specific_cf]
      wp.save!
    end
  end
  let(:wp_page) { Pages::FullWorkPackage.new(work_package) }
  let(:project_settings_page) { Pages::Projects::Settings.new(work_package.project) }

  before do
    login_as user
  end

  it "is only visible in the project if it has been activated" do
    wp_page.visit!

    wp_page.expect_attributes "customField#{for_all_cf.id}": "-"
    wp_page.expect_no_attribute "customField#{project_specific_cf.id}"

    project_settings_page.visit_tab!("custom_fields")

    project_settings_page.activate_wp_custom_field(project_specific_cf)

    project_settings_page.save!

    wp_page.visit!

    wp_page.expect_attributes "customField#{for_all_cf.id}": "-"
    wp_page.expect_attributes "customField#{project_specific_cf.id}": "-"
  end
end
