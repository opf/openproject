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

RSpec.describe Backlogs::Sprints::SetAttributesService, type: :model do
  let(:user) { build_stubbed(:user) }
  let(:contract_class) do
    contract = class_double(Backlogs::Sprints::CreateContract)

    allow(contract)
      .to receive(:new)
      .with(sprint, user, options: {})
      .and_return(contract_instance)

    contract
  end
  let(:contract_instance) do
    instance_double(ModelContract, validate: contract_valid, errors: contract_errors)
  end
  let(:contract_valid) { true }
  let(:contract_errors) do
    instance_double(ActiveModel::Errors)
  end
  let(:sprint_valid) { true }
  let(:instance) do
    described_class.new(user:,
                        model: sprint,
                        contract_class:,
                        contract_options: {})
  end
  let(:project) { create(:project) }
  let(:sprint) { Sprint.new }
  let(:params) { { project: } }

  subject(:service_call) { instance.call(params) }

  describe "call" do
    before do
      allow(sprint)
        .to receive(:valid?)
        .and_return(sprint_valid)

      allow(sprint).to receive(:save)
    end

    context "when contract validates and sprint is valid" do
      it "is successful" do
        expect(service_call).to be_success
      end

      it "sets the attributes on the sprint" do
        service_call

        # Default attributes set include:
        # * the project, since passed as argument
        # * a generated sprint sequence name if applicable, see `sprint_name_from_predecessor` specs.
        expect(sprint.changed_attributes).to include("project_id", "name")

        expect(sprint.project_id).to eq(project.id)
        expect(sprint.name).to eq("Sprint 1")
      end

      it "does not persist the sprint" do
        service_call

        expect(sprint).not_to have_received(:save)
      end
    end

    context "when contract does not validate" do
      let(:contract_valid) { false }

      it "is not successful" do
        expect(service_call).not_to be_success
      end
    end

    context "with params" do
      let(:params) do
        {
          name: "New Sprint Name",
          start_date: Time.zone.today,
          finish_date: Time.zone.today + 21.days,
          status: "active"
        }
      end

      before do
        allow(contract_instance)
          .to receive(:validate)
          .and_return(true)
      end

      it "passes the params to the sprint" do
        service_call

        expect(sprint.name).to eq("New Sprint Name")
        expect(sprint.start_date).to eq(Time.zone.today)
        expect(sprint.finish_date).to eq(Time.zone.today + 21.days)
        expect(sprint.status).to eq("active")
      end
    end

    describe "default attributes" do
      let(:sprint) { Sprint.new }

      it "sets default status to in_planning" do
        service_call

        expect(sprint.status).to eq("in_planning")
      end

      context "when status is already set" do
        let(:sprint) { Sprint.new(status: "active") }

        it "does not override the existing status" do
          service_call

          expect(sprint.status).to eq("active")
        end
      end
    end
  end

  describe "assigning a name" do
    context "when sprint is not a new record" do
      let(:sprint) { create(:sprint, project:, name: "Existing Sprint") }

      it "assigns the current name" do
        service_call

        expect(sprint.name).to eq("Existing Sprint")
      end
    end

    context "when sprint is a new record" do
      let(:sprint) { Sprint.new(project:) }

      context "when there is no predecessor sprint" do
        it "assigns a default name for the first sprint" do
          service_call

          expected_name = "#{I18n.t('activerecord.models.sprint')} 1"
          expect(sprint.name).to eq(expected_name)
        end
      end

      context "when there is a predecessor sprint with a name ending in a number" do
        it "increments the number for single-digit numbers" do
          create(:sprint, project:, name: "Sprint 1")

          service_call
          expect(sprint.name).to eq("Sprint 2")
        end

        it "increments the number for multi-digit numbers" do
          create(:sprint, project:, name: "Sprint 42")

          service_call
          expect(sprint.name).to eq("Sprint 43")
        end

        it "increments the number for custom names ending in numbers" do
          create(:sprint, project:, name: "Be ambitious 42")

          service_call
          expect(sprint.name).to eq("Be ambitious 43")
        end

        it "handles names with multiple spaces before the number" do
          create(:sprint, project:, name: "Release  99")

          service_call
          expect(sprint.name).to eq("Release  100")
        end

        it "increments from 9 to 10" do
          create(:sprint, project:, name: "Sprint 9")

          service_call
          expect(sprint.name).to eq("Sprint 10")
        end

        it "increments from 99 to 100" do
          create(:sprint, project:, name: "Sprint 99")

          service_call
          expect(sprint.name).to eq("Sprint 100")
        end
      end

      context "when there is a predecessor sprint with a custom name not ending in a number" do
        it "assigns an empty string" do
          create(:sprint, project:, name: "Custom Sprint Name")

          service_call
          expect(sprint.name).to eq("")
        end

        it "assigns an empty string for names with numbers in the middle" do
          create(:sprint, project:, name: "Sprint 2023 Planning")

          service_call
          expect(sprint.name).to eq("")
        end

        it "assigns an empty string for names ending with non-numeric characters" do
          create(:sprint, project:, name: "Sprint Alpha")

          service_call
          expect(sprint.name).to eq("")
        end
      end

      context "when there are multiple predecessor sprints" do
        it "uses the most recent sprint" do
          create(:sprint, project:, name: "Sprint 1", created_at: 2.days.ago)
          create(:sprint, project:, name: "Sprint 2", created_at: 1.day.ago)

          service_call
          expect(sprint.name).to eq("Sprint 3")
        end

        it "handles mixed naming patterns by using the most recent" do
          create(:sprint, project:, name: "Sprint 1", created_at: 2.days.ago)
          create(:sprint, project:, name: "Custom Name", created_at: 1.day.ago)

          service_call
          expect(sprint.name).to eq("")
        end
      end

      context "when there are sprints in other projects" do
        let(:other_project) { create(:project) }

        it "ignores sprints from other projects" do
          create(:sprint, project: other_project, name: "Other Sprint 5")

          service_call
          expect(sprint.name).to eq("#{I18n.t('activerecord.models.sprint')} 1")
        end

        it "only considers sprints from the same project" do
          create(:sprint, project: other_project, name: "Other Sprint 5")
          create(:sprint, project:, name: "Sprint 3")

          service_call
          expect(sprint.name).to eq("Sprint 4")
        end
      end
    end
  end
end
