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
require "services/base_services/behaves_like_create_service"

RSpec.describe Backlogs::Sprints::CreateService, type: :model do
  it_behaves_like "BaseServices create service" do
    let(:model_class) { Sprint }
    let(:factory) { :sprint }
  end

  describe "goal persistence" do
    let(:project) { create(:project) }
    let(:user) do
      create(:user, member_with_permissions: { project => %i[view_sprints create_sprints] })
    end
    let(:goals_attributes) { [{ project_id: project.id, text: goal_text }] }
    let(:attributes) do
      {
        project:,
        name: "Sprint 1",
        start_date: Time.zone.today,
        finish_date: Time.zone.today + 2.weeks,
        goals_attributes:
      }
    end
    let(:goal_text) { "Ship dashboard" }

    subject(:service_call) do
      described_class.new(user:).call(attributes:)
    end

    it "creates a goal for the new sprint's project" do
      expect { service_call }.to change(SprintGoal, :count).by(1)

      expect(service_call.result.goal_text_for(project)).to eq("Ship dashboard")
    end

    context "when the goal is blank" do
      let(:goal_text) { "" }

      it "does not create a goal" do
        expect { service_call }.not_to change(SprintGoal, :count)
      end
    end
  end
end
