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

RSpec.describe Planner::Task do
  let(:user) { build_stubbed(:user) }
  let(:referenced) { build_stubbed(:work_package, subject: "Show GitLab branches") }
  let(:references) { { referenced.id.to_s => referenced } }
  let(:subject_text) { "Ask about ##{referenced.id} and #999999" }
  let(:status) { build_stubbed(:status) }
  let(:work_package) { build_stubbed(:work_package, subject: subject_text, status:) }

  subject(:task) { described_class.new(work_package, references:, user:) }

  it "puts the visible referenced work packages in place of their references" do
    expect(task.subject_parts).to eq(["Ask about ", referenced, " and ", "#999999"])
    expect(task.planned_work_package).to be_nil
  end

  context "when the subject is nothing but a reference" do
    let(:subject_text) { " ##{referenced.id} " }

    it "stands for the referenced work package" do
      expect(task.planned_work_package).to eq(referenced)
    end
  end

  context "when the subject only references a work package the user cannot see" do
    let(:subject_text) { "#999999" }

    it "stands for no work package" do
      expect(task.planned_work_package).to be_nil
    end
  end

  context "with a /meeting command" do
    let(:subject_text) { "Set up a /meeting about wiki permissions" }

    it "offers the meeting while open" do
      expect(task.meeting_command.title).to eq("Wiki permissions")
    end

    context "when closed" do
      let(:status) { build_stubbed(:closed_status) }

      it "offers no meeting" do
        expect(task.meeting_command).to be_nil
      end
    end
  end
end
