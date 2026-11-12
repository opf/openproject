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

RSpec.describe CustomOptions::UpdateService do
  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }

  let(:custom_field) do
    create(:list_wp_custom_field, possible_values: %w[Berlin Munich], allow_additional_project_values: true)
  end
  let(:option) { custom_field.custom_options.create!(value: "Hamburg", project:) }

  subject(:result) { described_class.new(user: admin, model: option).call(value:) }

  context "with a new name" do
    let(:value) { "Bremen" }

    it "renames the option" do
      expect(result).to be_success
      expect(option.reload.value).to eq("Bremen")
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
