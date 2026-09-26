# frozen_string_literal: true

# --copyright
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
# ++

require "spec_helper"

RSpec.describe Query::Results, "Grouping and sorting for labels", with_flag: { work_package_labels: true } do
  let(:query_results) do
    described_class.new query
  end
  let(:project) { create(:project) }
  let(:user) do
    create(:user,
           firstname: "user",
           lastname: "1",
           member_with_permissions: { project => [:view_work_packages] })
  end

  let(:alpha_label) { create(:label, name: "alpha") }
  let(:bravo_label) { create(:label, name: "Bravo") }

  let!(:alpha_wp) do
    create_wp_with_labels("Alpha wp", [alpha_label])
  end
  let!(:both_labels_wp) do
    create_wp_with_labels("Both labels wp", [bravo_label, alpha_label])
  end
  let!(:bravo_wp) do
    create_wp_with_labels("Bravo wp", [bravo_label])
  end
  let!(:no_label_wp) do
    create(:work_package, subject: "No label wp", project:)
  end

  let(:group_by) { nil }
  let(:sort_criteria) { [["labels", "asc"]] }

  let(:query) do
    build(:query,
          user:,
          group_by:,
          show_hierarchies: false,
          project:).tap do |q|
      q.filters.clear
      q.sort_criteria = sort_criteria
    end
  end

  let(:work_packages_asc) { [alpha_wp, both_labels_wp, bravo_wp, no_label_wp] }
  let(:work_packages_desc) { work_packages_asc.reverse }

  def create_wp_with_labels(subject, labels, **attributes)
    create(:work_package, subject:, project:, **attributes).tap do |wp|
      labels.each do |label|
        create(:labeling, labelable: wp, label:)
      end
    end
  end

  before do
    login_as(user)
  end

  describe "sorting ASC by labels" do
    let(:sort_criteria) { [["labels", "asc"]] }

    it "sorts by the aggregated label names with absent labels last" do
      expect(query_results.work_packages.pluck(:id))
        .to eq work_packages_asc.map(&:id)
    end
  end

  describe "sorting DESC by labels" do
    let(:sort_criteria) { [["labels", "desc"]] }

    it "sorts by the aggregated label names with absent labels first" do
      expect(query_results.work_packages.pluck(:id))
        .to eq work_packages_desc.map(&:id)
    end
  end

  describe "grouping by labels" do
    let(:group_by) { "labels" }

    it "groups by the set of assigned labels" do
      expect(query_results.work_package_count_by_group)
        .to eql([alpha_label] => 1,
                [alpha_label, bravo_label] => 1,
                [bravo_label] => 1,
                [] => 1)

      expect(query_results.work_package_count_by_group.keys)
        .to eql [[alpha_label], [alpha_label, bravo_label], [bravo_label], []]

      expect(query_results.work_packages.pluck(:id))
        .to eq work_packages_asc.map(&:id)
    end

    context "with sums displayed" do
      let(:query) do
        build(:query,
              user:,
              group_by:,
              show_hierarchies: false,
              project:).tap do |q|
          q.filters.clear
          q.sort_criteria = sort_criteria
          q.display_sums = true
        end
      end

      let!(:alpha_wp) do
        create_wp_with_labels("Alpha wp", [alpha_label], estimated_hours: 2)
      end
      let!(:both_labels_wp) do
        create_wp_with_labels("Both labels wp", [bravo_label, alpha_label], estimated_hours: 3)
      end

      it "sums per label set" do
        sums = query_results.all_group_sums.transform_values do |by_column|
          by_column.transform_keys(&:name)[:estimated_hours]
        end

        expect(sums)
          .to eq([alpha_label] => 2.0,
                 [alpha_label, bravo_label] => 3.0,
                 [bravo_label] => nil,
                 [] => nil)
      end
    end
  end
end
