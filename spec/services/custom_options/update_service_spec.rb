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

RSpec.describe CustomOptions::UpdateService, with_ee: %i[project_specific_list_values] do
  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }

  let(:allow_additional_project_values) { true }
  let(:custom_field) do
    create(:list_wp_custom_field, possible_values: %w[Berlin Munich], allow_additional_project_values:)
  end
  let(:option) { custom_field.custom_options.create!(value: "Hamburg", project:) }
  let(:user) { admin }

  subject(:result) { described_class.new(user:, model: option).call(value:) }

  context "with a new name" do
    let(:value) { "Bremen" }

    it "renames the option" do
      expect(result).to be_success
      expect(option.reload.value).to eq("Bremen")
    end

    context "as a user allowed to manage custom field values in the project" do
      let(:user) { create(:user, member_with_permissions: { project => %i[manage_work_package_custom_field_values] }) }

      it "renames the option" do
        expect(result).to be_success
        expect(option.reload.value).to eq("Bremen")
      end
    end

    context "when the custom field does not allow additional project values" do
      let(:allow_additional_project_values) { false }

      it "keeps the name" do
        expect(result).to be_failure
        expect(result.errors.symbols_for(:project_id)).to include(:additional_values_not_allowed)
        expect(option.reload.value).to eq("Hamburg")
      end
    end
  end

  context "with the name of a global option" do
    let(:value) { "berlin" }

    it "fails" do
      expect(result).to be_failure
      expect(result.errors.symbols_for(:value)).to include(:taken)
      expect(option.reload.value).to eq("Hamburg")
    end
  end

  context "with the name of an option of another project" do
    let(:value) { "Bremen" }

    before do
      custom_field.custom_options.create!(value: "Bremen", project: other_project)
    end

    it "renames the option" do
      expect(result).to be_success
    end
  end

  context "when changing the project" do
    subject(:result) { described_class.new(user: admin, model: option).call(project: other_project) }

    it "fails" do
      expect(result).to be_failure
      expect(option.reload.project).to eq(project)
    end
  end
end
