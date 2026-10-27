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

RSpec.describe Queries::Projects::Filters::ProjectSpecificValuesFilter do
  it_behaves_like "basic query filter" do
    let(:class_key) { :project_specific_values }
    let(:type) { :list }
    let(:human_name) { "Project-specific values" }
  end

  describe "#available?" do
    it "is offered to administrators only" do
      allow(User).to receive(:current).and_return(build_stubbed(:admin))
      expect(described_class.create!(name: :project_specific_values, operator: "=")).to be_available

      allow(User).to receive(:current).and_return(build_stubbed(:user))
      expect(described_class.create!(name: :project_specific_values, operator: "=")).not_to be_available
    end
  end

  describe "#valid?" do
    shared_let(:custom_field) { create(:list_wp_custom_field, :project_specific_allowlist) }

    subject(:filter) do
      described_class.create!(name: :project_specific_values, operator: "=", values: [custom_field.id.to_s])
    end

    context "for an administrator" do
      current_user { build_stubbed(:admin) }

      it { is_expected.to be_valid }
    end

    context "for a non-administrator" do
      current_user { build_stubbed(:user) }

      it { is_expected.not_to be_valid }
    end
  end

  describe "#apply_to" do
    shared_let(:custom_field) { create(:list_wp_custom_field, :project_specific_allowlist, possible_values: %w[A]) }
    shared_let(:other_custom_field) { create(:list_wp_custom_field, :project_specific_allowlist, possible_values: %w[A]) }
    shared_let(:configured_project) { create(:project) }
    shared_let(:otherwise_configured_project) { create(:project) }
    shared_let(:unconfigured_project) { create(:project) }

    subject(:filter) do
      described_class.create!(name: :project_specific_values, operator: "=", values: [custom_field.id.to_s])
    end

    before do
      create(:project_specific_value_restriction, project: configured_project,
                                                  custom_option: custom_field.custom_options.first)
      create(:project_specific_value_restriction, project: otherwise_configured_project,
                                                  custom_option: other_custom_field.custom_options.first)
    end

    it "keeps the projects with project-specific values of the custom field" do
      expect(filter.apply_to(Project)).to contain_exactly(configured_project)
    end
  end

  describe "in a project query" do
    context "for an administrator" do
      current_user { build_stubbed(:admin) }

      it "is available, but not offered as an advanced filter" do
        query = ProjectQuery.new

        expect(query.available_filters.map(&:class)).to include(described_class)
        expect(query.available_advanced_filters.map(&:class)).not_to include(described_class)
      end
    end

    context "for a non-administrator" do
      current_user { build_stubbed(:user) }

      it "makes the query invalid" do
        custom_field = create(:list_wp_custom_field, :project_specific_allowlist)
        query = ProjectQuery.new.where(:project_specific_values, "=", [custom_field.id.to_s])

        expect(query).not_to be_valid
        expect(query.errors.full_messages.join).to include(I18n.t(:"activerecord.errors.messages.filter_does_not_exist"))
      end
    end
  end
end
