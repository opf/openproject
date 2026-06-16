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

RSpec.describe Backlogs::Sprints::StartContract do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:sprint) do
    create(:sprint,
           project:,
           status: sprint_status)
  end
  let(:sprint_status) { "in_planning" }
  let(:permissions) { [:start_complete_sprint] }

  subject(:contract) { described_class.new(sprint, user) }

  before do
    mock_permissions_for(user) do |mock|
      mock.allow_in_project(*permissions, project:)
    end
  end

  describe "validation" do
    context "with valid sprint and permissions" do
      it "is valid" do
        expect(contract.validate).to be(true)
      end
    end

    context "without start_complete_sprint permission" do
      let(:permissions) { [:view_work_packages] }

      it "is invalid" do
        expect(contract.validate).to be(false)
        expect(contract.errors.symbols_for(:base)).to include(:error_unauthorized)
      end
    end

    context "when sprint is active" do
      let(:sprint_status) { "active" }

      it "is invalid" do
        expect(contract.validate).to be(false)
        expect(contract.errors.symbols_for(:status)).to include(:must_be_in_planning)
      end
    end

    context "when sprint is completed" do
      let(:sprint_status) { "completed" }

      it "is invalid" do
        expect(contract.validate).to be(false)
        expect(contract.errors.symbols_for(:status)).to include(:must_be_in_planning)
      end
    end

    context "when the sprint has no start date" do
      let(:sprint) { create(:sprint, project:, status: sprint_status, start_date: nil) }

      it "is invalid" do
        expect(contract.validate).to be(false)
        expect(contract.errors.symbols_for(:base)).to include(:dates_required)
      end
    end

    context "when the sprint has no finish date" do
      let(:sprint) { create(:sprint, project:, status: sprint_status, finish_date: nil) }

      it "is invalid" do
        expect(contract.validate).to be(false)
        expect(contract.errors.symbols_for(:base)).to include(:dates_required)
      end
    end

    context "when another active sprint exists in the project" do
      before do
        create(:sprint,
               project:,
               status: "active")
      end

      it "is invalid" do
        expect(contract.validate).to be(false)
        expect(contract.errors.symbols_for(:status)).to include(:only_one_active_sprint_allowed)
      end
    end

    context "when an active sprint exists in a different project" do
      before do
        create(:sprint,
               project: create(:project),
               status: "active")
      end

      it "is valid" do
        expect(contract.validate).to be(true)
      end
    end
  end
end
