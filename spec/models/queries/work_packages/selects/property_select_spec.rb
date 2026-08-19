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
require_relative "shared_query_select_specs"

RSpec.describe Queries::WorkPackages::Selects::PropertySelect do
  let(:instance) { described_class.new(:query_column) }

  it_behaves_like "query column"

  describe "instances" do
    it "the done_ratio column exists" do
      expect(described_class.instances.map(&:name)).to include :done_ratio
    end

    context "when duration feature flag enabled" do
      it "column exists" do
        expect(described_class.instances.map(&:name)).to include :duration
      end
    end

    describe "version and target_versions columns" do
      context "with the feature flag and the setting enabled",
              with_flag: { work_package_multiple_versions: true },
              with_settings: { work_package_multiple_versions: true } do
        it "replaces the version column with the target_versions column" do
          names = described_class.instances.map(&:name)

          expect(names).to include :target_versions
          expect(names).not_to include :version
        end

        it "is displayable but neither sortable nor groupable" do
          column = described_class.instances.find { it.name == :target_versions }

          expect(column).to be_displayable
          expect(column).not_to be_sortable
          expect(column).not_to be_groupable
          expect(column.caption).to eq WorkPackage.human_attribute_name(:target_versions)
        end
      end

      context "with the feature flag disabled",
              with_flag: { work_package_multiple_versions: false },
              with_settings: { work_package_multiple_versions: true } do
        it "keeps the version column" do
          names = described_class.instances.map(&:name)

          expect(names).to include :version
          expect(names).not_to include :target_versions
        end
      end

      context "with the setting disabled",
              with_flag: { work_package_multiple_versions: true },
              with_settings: { work_package_multiple_versions: false } do
        it "keeps the version column" do
          names = described_class.instances.map(&:name)

          expect(names).to include :version
          expect(names).not_to include :target_versions
        end
      end

      context "with the feature flag and the setting disabled",
              with_flag: { work_package_multiple_versions: false },
              with_settings: { work_package_multiple_versions: false } do
        it "keeps the version column" do
          names = described_class.instances.map(&:name)

          expect(names).to include :version
          expect(names).not_to include :target_versions
        end
      end
    end
  end
end
