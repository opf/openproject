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
# frozen_string_literal: true

require "spec_helper"
require_relative "../../support/query_counter"

RSpec.describe ::Screens::RequiredSet do
  let(:project) { create(:project) }
  let(:type) { create(:type) }

  before do
    create(:project_type, project:, type:)
  end

  describe ".for" do
    it "always includes subject" do
      expect(described_class.for(project, type)).to include("subject")
    end

    it "includes required custom fields active in the project" do
      custom_field = create(:work_package_custom_field, is_required: true)
      project.work_package_custom_field_ids = [custom_field.id]
      project.save!

      expect(described_class.for(project.reload, type)).to include("custom_field_#{custom_field.id}")
    end

    it "excludes required custom fields that have a default" do
      custom_field = create(:work_package_custom_field, is_required: true, default_value: "value")
      project.work_package_custom_field_ids = [custom_field.id]
      project.save!

      expect(described_class.for(project.reload, type)).not_to include("custom_field_#{custom_field.id}")
    end

    it "uses at most 4 queries" do
      described_class.for(project, type)
      count = ScreensQueryCounter.count { described_class.for(project, type) }
      expect(count).to be <= 4
    end
  end

  describe ".for_scheme_type" do
    let(:scheme) { create(:screen_scheme) }

    before { create(:screen_scheme_item, scheme:, type:, create_screen: create(:create_screen)) }

    it "returns one entry per project using the scheme" do
      create(:project_screen_scheme, project:, scheme:)
      result = described_class.for_scheme_type(scheme, type)
      expect(result.keys).to contain_exactly(project.id)
    end

    it "skips very large schemes" do
      stub_const("Screens::RequiredSet::MAX_PROJECTS", 0)
      create(:project_screen_scheme, project:, scheme:)
      expect(described_class.for_scheme_type(scheme, type)).to eq(:skipped)
    end
  end
end
