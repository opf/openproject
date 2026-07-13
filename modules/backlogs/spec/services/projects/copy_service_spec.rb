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

require "rails_helper"

RSpec.describe Projects::CopyService, "backlogs settings", type: :model do
  shared_let(:open_status) { create(:status, is_closed: false) }
  shared_let(:closed_status) { create(:status, is_closed: true) }
  shared_let(:type_story) { create(:type, name: "Story") }
  shared_let(:type_task) { create(:type, name: "Task") }

  let(:user) { create(:admin) }
  let(:instance) { described_class.new(source:, user:) }
  let(:params) do
    {
      target_project_params: { name: "Copied Project", identifier: "copied-project" },
      only: []
    }
  end

  subject(:result) { instance.call(params) }

  context "when the backlogs module is enabled on the source project" do
    let(:source) do
      create(:project,
             enabled_module_names: %w[backlogs work_package_tracking],
             types: [type_story, type_task]) do |p|
        p.done_statuses = [open_status, closed_status]
        p.backlog_excluded_types = [type_task]
      end
    end

    it "is successful" do
      expect(result).to be_success
    end

    it "copies the done_statuses to the new project" do
      expect(result.result.done_statuses).to contain_exactly(open_status, closed_status)
    end

    it "copies the backlog_excluded_types to the new project" do
      expect(result.result.backlog_excluded_types).to contain_exactly(type_task)
    end

    it "does not couple copied associations to the source project" do
      copied = result.result

      source_done_status_ids_before = source.done_status_ids.uniq
      source_excluded_type_ids_before = source.backlog_excluded_type_ids.uniq

      expect(copied.done_status_ids.uniq).to match_array(source_done_status_ids_before)
      expect(copied.backlog_excluded_type_ids.uniq).to match_array(source_excluded_type_ids_before)

      copied.done_statuses = [closed_status]
      copied.backlog_excluded_types = [type_story]
      copied.save!

      source.reload
      copied.reload

      expect(source.done_status_ids.uniq).to match_array(source_done_status_ids_before)
      expect(source.backlog_excluded_type_ids.uniq).to match_array(source_excluded_type_ids_before)

      expect(copied.done_status_ids.uniq).to contain_exactly(closed_status.id)
      expect(copied.backlog_excluded_type_ids.uniq).to contain_exactly(type_story.id)
    end
  end

  context "when the backlogs module is enabled on the source project but associations are empty" do
    let(:source) do
      # done_statuses and backlog_excluded_types are intentionally left empty
      create(:project,
             enabled_module_names: %w[backlogs work_package_tracking],
             types: [type_story, type_task])
    end

    before do
      # Clear any done_statuses that were auto-seeded when the module was enabled
      source.done_statuses = []
    end

    it "is successful" do
      expect(result).to be_success
    end

    it "results in an empty done_statuses on the new project" do
      expect(result.result.done_statuses).to be_empty
    end

    it "results in empty backlog_excluded_types on the new project" do
      expect(result.result.backlog_excluded_types).to be_empty
    end
  end

  context "when the backlogs module is NOT enabled on the source project" do
    let(:source) do
      create(:project,
             enabled_module_names: %w[work_package_tracking],
             types: [type_story, type_task])
    end

    it "is successful" do
      expect(result).to be_success
    end

    it "does not set any done_statuses on the new project" do
      expect(result.result.done_statuses).to be_empty
    end

    it "does not set any backlog_excluded_types on the new project" do
      expect(result.result.backlog_excluded_types).to be_empty
    end
  end
end
