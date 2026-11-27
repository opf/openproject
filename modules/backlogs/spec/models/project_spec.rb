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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Project do
  describe "associations" do
    it { is_expected.to have_many(:sprints).class_name("Sprint").dependent(:destroy) }
    it { is_expected.to have_many(:backlog_buckets).class_name("BacklogBucket").dependent(:destroy) }
  end

  # The two are exact complements and have to stay so, hence every example asserting both.
  describe "#statuses_considered_closed and #statuses_considered_open" do
    subject(:project) { create(:project) }

    shared_let(:open_status) { create(:status, name: "Open") }
    shared_let(:globally_closed_status) { create(:closed_status, name: "Rejected") }
    shared_let(:configurable_status) { create(:status, name: "Delivered") }

    def closed = project.statuses_considered_closed
    def open = project.statuses_considered_open

    context "when the project configures no done statuses of its own" do
      # Enabling the backlogs module pre-populates done_statuses with the globally closed ones
      # (see the MODULE_ENABLED subscriber in the engine), so reaching the unconfigured case at
      # all means emptying it again.
      before { project.done_statuses = [] }

      it "counts the globally closed ones, so an unconfigured project still sees finished work" do
        expect(closed).to contain_exactly(globally_closed_status)
        expect(open).to contain_exactly(open_status, configurable_status)
      end
    end

    context "when the project configures a done status that is not globally closed" do
      before { project.done_statuses = [configurable_status] }

      it "counts it alongside the globally closed ones" do
        expect(closed).to contain_exactly(globally_closed_status, configurable_status)
        expect(open).to contain_exactly(open_status)
      end
    end

    context "when the project configures a status that is globally closed anyway" do
      before { project.done_statuses = [globally_closed_status] }

      it "counts it once rather than twice" do
        expect(closed).to contain_exactly(globally_closed_status)
        expect(open).to contain_exactly(open_status, configurable_status)
      end
    end

    context "when the project configures every status as done" do
      before { project.done_statuses = Status.all.to_a }

      it "leaves nothing open" do
        expect(closed).to contain_exactly(open_status, globally_closed_status, configurable_status)
        expect(open).to be_empty
      end
    end

    # done_statuses is per project, so one project's configuration must not reach another's reports.
    context "when another project configures a done status" do
      before { create(:project).done_statuses = [configurable_status] }

      it "is unaffected by it" do
        expect(closed).to contain_exactly(globally_closed_status)
        expect(open).to contain_exactly(open_status, configurable_status)
      end
    end
  end
end
