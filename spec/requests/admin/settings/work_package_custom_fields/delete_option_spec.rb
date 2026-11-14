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

RSpec.describe "Deleting an option of a work package custom field", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:work_package) { create(:work_package) }

  let(:custom_field) { create(:list_wp_custom_field, possible_values: %w[Berlin Hamburg]) }
  let(:berlin) { custom_field.custom_options.find_by!(value: "Berlin") }
  let(:hamburg) { custom_field.custom_options.find_by!(value: "Hamburg") }
  let!(:berlin_value) { create(:custom_value, custom_field:, customized: work_package, value: berlin.id.to_s) }
  let!(:hamburg_value) { create(:custom_value, custom_field:, customized: work_package, value: hamburg.id.to_s) }

  before { login_as admin }

  it "deletes the option and the values referencing it" do
    delete delete_option_of_admin_settings_work_package_custom_field_path(custom_field, option_id: berlin.id)

    expect(response).to have_http_status(:see_other)
    expect(flash[:notice]).to eq(I18n.t(:notice_custom_options_deleted, option_value: "Berlin", num_deleted: 1))
    expect(CustomOption.exists?(berlin.id)).to be(false)
    expect(CustomValue.exists?(berlin_value.id)).to be(false)
    expect(CustomValue.exists?(hamburg_value.id)).to be(true)
  end
end
