# frozen_string_literal: true

# -- copyright
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

RSpec.describe WorkPackages::Scopes::WithBacklogsNeighbours do
  let(:project) { create(:project) }
  let(:open_status) { create(:status, is_closed: false) }
  let(:closed_status) { create(:status, is_closed: true) }

  let(:neighbours_scope) { WorkPackage.where(project:).order_by_position.with_backlogs_neighbours }

  describe ".with_backlogs_neighbours" do
    context "with four items" do
      # Created in scrambled order so id sequence is not the same as the position
      let!(:wp1) { create(:work_package, project:, status: open_status, position: 1) }
      let!(:wp4) { create(:work_package, project:, status: open_status, position: 4) }
      let!(:wp2) { create(:work_package, project:, status: open_status, position: 2) }
      let!(:wp3) { create(:work_package, project:, status: open_status, position: 3) }

      context "for the first item" do
        subject { neighbours_scope.find(wp1.id) }

        it { is_expected.to have_attributes(prev_prev_id: nil, prev_id: nil, next_id: wp2.id) }
      end

      context "for the second item" do
        subject { neighbours_scope.find(wp2.id) }

        it { is_expected.to have_attributes(prev_prev_id: nil, prev_id: wp1.id, next_id: wp3.id) }
      end

      context "for a middle item with two predecessors" do
        subject { neighbours_scope.find(wp3.id) }

        it { is_expected.to have_attributes(prev_prev_id: wp1.id, prev_id: wp2.id, next_id: wp4.id) }
      end

      context "for the last item" do
        subject { neighbours_scope.find(wp4.id) }

        it { is_expected.to have_attributes(prev_prev_id: wp2.id, prev_id: wp3.id, next_id: nil) }
      end
    end

    context "when items have nil positions, tiebroken by id" do
      let!(:wp_with_pos) { create(:work_package, project:, status: open_status, position: 1) }
      # Bypass acts_as_list callbacks to force nil positions, simulating unpositioned items
      let!(:wp_nil_lower_id) do
        create(:work_package, project:, status: open_status, position: nil).tap { |wp| wp.update_columns(position: nil) }
      end
      let!(:wp_nil_higher_id) do
        create(:work_package, project:, status: open_status).tap { |wp| wp.update_columns(position: nil) }
      end

      context "for the nil-position item with the lower id" do
        subject { neighbours_scope.find(wp_nil_lower_id.id) }

        it { is_expected.to have_attributes(prev_prev_id: nil, prev_id: wp_with_pos.id, next_id: wp_nil_higher_id.id) }
      end

      context "for the nil-position item with the higher id" do
        subject { neighbours_scope.find(wp_nil_higher_id.id) }

        it { is_expected.to have_attributes(prev_prev_id: wp_with_pos.id, prev_id: wp_nil_lower_id.id, next_id: nil) }
      end
    end

    context "when the scope excludes closed work packages" do
      let(:project) { create(:project) }
      let(:neighbours_scope) { WorkPackage.where(project:, status: open_status).order_by_position.with_backlogs_neighbours }
      let!(:first_open) { create(:work_package, project:, status: open_status, position: 1) }
      let!(:closed_wp) { create(:work_package, project:, status: closed_status, position: 2) }
      let!(:last_open) { create(:work_package, project:, status: open_status, position: 3) }

      subject { neighbours_scope.find(last_open.id) }

      it { is_expected.to have_attributes(prev_prev_id: nil, prev_id: first_open.id, next_id: nil) }
    end

    context "when the scope excludes work packages of an excluded type" do
      let(:project) { create(:project) }
      let(:neighbours_scope) { WorkPackage.where(project:, type: included_type).order_by_position.with_backlogs_neighbours }
      let(:included_type) { create(:type_feature) }
      let(:excluded_type) { create(:type_task) }
      let!(:first_included) { create(:work_package, project:, status: open_status, type: included_type, position: 1) }
      let!(:excluded_wp) { create(:work_package, project:, status: open_status, type: excluded_type, position: 2) }
      let!(:last_included) { create(:work_package, project:, status: open_status, type: included_type, position: 3) }

      subject { neighbours_scope.find(last_included.id) }

      it { is_expected.to have_attributes(prev_prev_id: nil, prev_id: first_included.id, next_id: nil) }
    end
  end
end
