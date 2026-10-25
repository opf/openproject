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

RSpec.describe CreatedResolved do
  def set_attribute_journalized(work_package, attribute, value, time)
    work_package.reload
    work_package.send(attribute, value)
    work_package.save!
    work_package.journals[-2].update_columns(validity_period: work_package.journals[-2].created_at...time)
    work_package.journals[-1].update_columns(created_at: time, updated_at: time, validity_period: time..Float::INFINITY)
  end

  def create_backdated_work_package(sprint:)
    created_at = Time.zone.today - 20.days
    work_package = create(:work_package, project:, sprint:, status: status_open, created_at:, updated_at: created_at)
    work_package.last_journal.update_columns(created_at:, updated_at: created_at, validity_period: created_at..Float::INFINITY)
    work_package
  end

  let(:project) { create(:project) }
  let(:role) { create(:project_role, permissions: %i[view_work_packages]) }
  let(:status_open) { create(:status, is_default: true) }
  let(:status_done) { create(:status) }
  let(:status_closed) { create(:status, is_closed: true) }

  let!(:non_working_days) do
    [
      create(:non_working_day, date: Date.new(2011, 4, 2)),
      create(:non_working_day, date: Date.new(2011, 4, 3))
    ]
  end

  current_user { create(:user, member_with_roles: { project => role }) }

  subject(:created_resolved) { described_class.new(sprint, project) }

  around do |example|
    travel_to(Time.utc(2011, "apr", 4, 20, 15, 1)) { example.run }
  end

  before do
    project.done_statuses << status_done
  end

  context "with a sprint that is 6 working days in" do
    let(:sprint) do
      create(:sprint, project:, start_date: Date.new(2011, 3, 28), finish_date: Date.new(2011, 4, 8))
    end

    let!(:planned) { Array.new(3) { create_backdated_work_package(sprint:) } }
    let!(:added_later) { create_backdated_work_package(sprint: nil) }

    before do
      set_attribute_journalized planned[0], :status=, status_done, Time.zone.parse("2011-03-29 10:00")
      set_attribute_journalized added_later, :sprint=, sprint, Time.zone.parse("2011-03-30 10:00")
      set_attribute_journalized planned[1], :sprint=, nil, Time.zone.parse("2011-03-31 10:00")
      set_attribute_journalized planned[2], :status=, status_done, Time.zone.parse("2011-04-01 10:00")
    end

    it "counts the work packages in the sprint at the end of each elapsed day" do
      expect(created_resolved.series[:wp_created]).to eql [3.0, 3.0, 4.0, 3.0, 3.0, 3.0]
    end

    it "counts the work packages in a done status in the sprint at the end of each elapsed day" do
      expect(created_resolved.series[:wp_resolved]).to eql [0.0, 1.0, 1.0, 1.0, 2.0, 2.0]
    end

    it "does not count resolved work packages again when they are edited later" do
      set_attribute_journalized planned[0], :subject=, "Edited", Time.zone.parse("2011-04-04 10:00")

      expect(created_resolved.series[:wp_resolved]).to eql [0.0, 1.0, 1.0, 1.0, 2.0, 2.0]
    end

    it "counts work packages in a globally closed status as resolved" do
      set_attribute_journalized planned[2], :status=, status_closed, Time.zone.parse("2011-04-04 10:00")
      set_attribute_journalized added_later, :status=, status_closed, Time.zone.parse("2011-04-04 11:00")

      expect(created_resolved.series[:wp_resolved]).to eql [0.0, 1.0, 1.0, 1.0, 2.0, 3.0]
    end

    it "reports the maxima" do
      expect(created_resolved.max).to eq(wp_created: 4.0, wp_resolved: 2.0)
    end
  end

  context "with a sprint starting with a work package already done" do
    let(:sprint) do
      create(:sprint, project:, start_date: Date.new(2011, 3, 31), finish_date: Date.new(2011, 4, 8))
    end

    before do
      create_backdated_work_package(sprint:)
      done = create_backdated_work_package(sprint:)
      set_attribute_journalized done, :status=, status_done, Time.zone.parse("2011-03-20 10:00")
    end

    it { expect(created_resolved.series[:wp_resolved]).to eql [1.0, 1.0, 1.0] }
  end
end
