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

RSpec.describe WorkPackages::CopyService, "with project-specific custom field values" do
  shared_let(:admin) { create(:admin) }
  shared_let(:type) { create(:type) }
  shared_let(:source_project) { create(:project, types: [type]) }
  shared_let(:target_project) { create(:project, types: [type]) }

  let(:custom_field) do
    create(:list_wp_custom_field, :project_specific_allowlist, types: [type], possible_values: %w[A B], multi_value:)
  end
  let(:multi_value) { false }
  let(:option_a) { custom_field.custom_options.find_by!(value: "A") }
  let(:option_b) { custom_field.custom_options.find_by!(value: "B") }
  let(:work_package) do
    create(:work_package, project: source_project, type:, custom_values: { custom_field.id => values })
  end
  let(:copy) { service_call.result }

  before do
    create(:project_specific_value_restriction, project: source_project, custom_option: option_a)
    create(:project_specific_value_restriction, project: source_project, custom_option: option_b)
    create(:project_specific_value_restriction, project: target_project, custom_option: option_a)
  end

  context "when copying into another project" do
    subject(:service_call) { described_class.new(user: admin, work_package:).call(project: target_project) }

    context "with an option usable in the target project" do
      let(:values) { option_a.id.to_s }

      it "keeps the option" do
        expect(service_call).to be_success
        expect(copy.public_send(custom_field.attribute_getter)).to eq("A")
      end
    end

    context "with an option that is not usable in the target project" do
      let(:values) { option_b.id.to_s }

      it "drops the option" do
        expect(service_call).to be_success
        expect(copy.public_send(custom_field.attribute_getter)).to be_nil
      end
    end

    context "with options of a multi-select field" do
      let(:multi_value) { true }
      let(:values) { [option_a.id.to_s, option_b.id.to_s] }

      it "only keeps the options usable in the target project" do
        expect(service_call).to be_success
        expect(copy.public_send(custom_field.attribute_getter)).to eq(%w[A])
      end
    end
  end

  context "when copying within the same project" do
    subject(:service_call) { described_class.new(user: admin, work_package:).call }

    let(:values) { option_b.id.to_s }

    it "keeps the option" do
      expect(service_call).to be_success
      expect(copy.public_send(custom_field.attribute_getter)).to eq("B")
    end
  end
end
