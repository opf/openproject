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

RSpec.describe ResourcePlannerViews::UserCardList::CardFieldCatalog do
  shared_let(:admin) { create(:admin) }
  shared_let(:section) { create(:user_custom_field_section) }
  shared_let(:skills_cf) do
    create(:user_custom_field, name: "Skills", field_format: "string", user_custom_field_section: section)
  end
  shared_let(:job_title_cf) do
    create(:user_custom_field, name: "Position", field_format: "string",
                               user_custom_field_section: section, semantic_key: "job_title")
  end

  before { login_as(admin) }

  describe ".options" do
    subject(:ids) { described_class.options.pluck(:id) }

    it "offers the built-in fields and selectable custom fields" do
      expect(ids).to include("department", "working_times", skills_cf.column_name)
    end

    it "excludes the custom field carrying the job_title semantic key" do
      expect(ids).not_to include(job_title_cf.column_name)
    end

    it "labels the built-ins from i18n / user attributes" do
      labels = described_class.options.index_by { |option| option[:id] }

      expect(labels["department"][:name]).to eq(User.human_attribute_name(:department))
      expect(labels["working_times"][:name]).to eq(I18n.t("resource_management.user_card_list.fields.working_times"))
    end
  end

  describe ".allowed_ids" do
    it "returns the set of valid identifiers" do
      expect(described_class.allowed_ids).to include("department", "working_times", skills_cf.column_name)
      expect(described_class.allowed_ids).not_to include(job_title_cf.column_name)
    end
  end

  describe ".selected_options" do
    it "preserves the given order and drops unknown identifiers" do
      result = described_class.selected_options(["working_times", "bogus", "department"])

      expect(result.pluck(:id)).to eq(%w[working_times department])
    end
  end
end
