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

RSpec.describe CustomOptions::DeleteService do
  shared_let(:project) { create(:project) }
  shared_let(:custom_field) do
    create(:list_wp_custom_field, possible_values: %w[Berlin], allow_additional_project_values: true)
  end
  shared_let(:work_package) { create(:work_package, project:) }

  let(:custom_option) { custom_field.custom_options.create!(value: "Hamburg", project:) }
  let!(:custom_value) do
    create(:custom_value, custom_field:, customized: work_package, value: custom_option.id.to_s)
  end
  let!(:other_custom_value) do
    create(:custom_value, custom_field:, customized: work_package, value: custom_field.custom_options.first.id.to_s)
  end

  subject(:service_call) { described_class.new(user:, model: custom_option).call }

  context "as a user allowed to manage custom field values in the project" do
    let(:user) { create(:user, member_with_permissions: { project => %i[manage_work_package_custom_field_values] }) }

    it "deletes the option and the values referencing it" do
      expect(service_call).to be_success

      expect(CustomOption.exists?(custom_option.id)).to be(false)
      expect(CustomValue.exists?(custom_value.id)).to be(false)
      expect(CustomValue.exists?(other_custom_value.id)).to be(true)
    end
  end

  context "as a user not allowed to manage custom field values in the project" do
    let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

    it "keeps the option and its values" do
      expect(service_call).to be_failure

      expect(CustomOption.exists?(custom_option.id)).to be(true)
      expect(CustomValue.exists?(custom_value.id)).to be(true)
    end
  end
end
