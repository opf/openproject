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

RSpec.describe Query::Results, "Filtering by version" do
  let(:project) { create(:project) }
  let(:user) do
    create(:user,
           member_with_permissions: { project => [:view_work_packages] })
  end

  let(:searched_version) { create(:version, project:, name: "Searched version") }
  let(:other_version) { create(:version, project:, name: "Other version") }

  # The legacy version_id column mirrors only the first target version. This
  # work package targets the searched version as its second target, so it is
  # only found when filtering through the target version associations.
  let!(:wp_with_searched_as_second_target) do
    create(:work_package, project:, version: other_version).tap do |wp|
      create(:work_package_version, work_package: wp, version: searched_version, kind: :target)
    end
  end
  let!(:wp_with_searched_as_only_target) do
    create(:work_package, project:, version: searched_version)
  end
  let!(:wp_with_other_target) do
    create(:work_package, project:, version: other_version)
  end

  let(:operator) { "=" }
  let(:values) { [searched_version.id.to_s] }

  let(:query) do
    build(:query, user:, project:).tap do |q|
      q.filters.clear
      q.add_filter("version_id", operator, values)
    end
  end

  subject(:results) { described_class.new(query).work_packages }

  before { login_as(user) }

  context "with the multiple versions feature active",
          with_flag: { work_package_multiple_versions: true },
          with_settings: { work_package_multiple_versions: true } do
    it "returns work packages targeting the version, regardless of the mirrored version_id column" do
      expect(results)
        .to contain_exactly(wp_with_searched_as_second_target, wp_with_searched_as_only_target)
    end

    context 'with the "!" operator' do
      let(:operator) { "!" }

      it "returns only work packages not targeting the version at all" do
        expect(results).to contain_exactly(wp_with_other_target)
      end
    end
  end

  context "with the multiple versions feature inactive",
          with_flag: { work_package_multiple_versions: false } do
    it "returns only work packages with the version in the version_id column" do
      expect(results).to contain_exactly(wp_with_searched_as_only_target)
    end
  end
end
