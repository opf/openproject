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

RSpec.describe Queries::Projects::Filters::AvailableCustomFieldsProjectsFilter do
  it_behaves_like "basic query filter" do
    let(:class_key) { :available_custom_fields_projects }
    let(:type) { :list }
    let(:human_name) { "Available custom fields projects" }
  end

  describe "#available?" do
    it "is offered to administrators only" do
      allow(User).to receive(:current).and_return(build_stubbed(:admin))
      expect(described_class.create!(name: :available_custom_fields_projects, operator: "=")).to be_available

      allow(User).to receive(:current).and_return(build_stubbed(:user))
      expect(described_class.create!(name: :available_custom_fields_projects, operator: "=")).not_to be_available
    end
  end

  describe "#apply_to" do
    shared_let(:type) { create(:type) }
    shared_let(:custom_field) { create(:integer_wp_custom_field) }
    shared_let(:showing) { create(:project, types: [type]) }
    shared_let(:bystander) { create(:project, no_types: true) }

    before do
      base = type.default_variant
      base.custom_field_ids = [custom_field.id]
      base.attribute_groups = [["Details", [custom_field.attribute_name]]]
      base.save!
    end

    subject(:filter) do
      described_class.create!(name: :available_custom_fields_projects, operator:, values: [custom_field.id.to_s])
    end

    context 'for "="' do
      let(:operator) { "=" }

      it "keeps the projects whose form configuration shows the field" do
        expect(filter.apply_to(Project)).to contain_exactly(showing)
      end
    end

    context 'for "!"' do
      let(:operator) { "!" }

      it "keeps the projects whose form configuration does not" do
        expect(filter.apply_to(Project)).to include(bystander)
        expect(filter.apply_to(Project)).not_to include(showing)
      end
    end
  end

  describe "#allowed_values" do
    shared_let(:custom_field) { create(:integer_wp_custom_field, name: "Story points") }

    it "offers the work package custom fields" do
      filter = described_class.create!(name: :available_custom_fields_projects, operator: "=")

      expect(filter.allowed_values).to include(["Story points", custom_field.id])
    end
  end
end
