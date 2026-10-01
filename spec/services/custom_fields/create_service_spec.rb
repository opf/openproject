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

RSpec.describe CustomFields::CreateService, type: :model do
  it_behaves_like "BaseServices create service" do
    context "when creating a project cf" do
      let(:model_instance) { build_stubbed(:project_custom_field) }

      it "no longer changes the enabled_projects_columns setting" do
        expect { subject }
          .not_to change(Setting, :enabled_projects_columns)
        expect(subject).to be_success
      end
    end
  end

  describe "#call" do
    shared_let(:user) { create(:admin) }

    let!(:contract_instance) do
      instance_double(contract_class, validate: true).tap do |contract|
        allow(contract_class)
          .to receive(:new).with(instance_of(custom_field_class), user, options: {}).and_return(contract)
      end
    end

    let(:contract_class) { CustomFields::CreateContract }
    let(:custom_field_class) { ProjectCustomField }
    let(:instance) { described_class.new(user:) }

    current_user { user }

    subject(:instance_call) { instance.call(attributes) }

    describe "calculated value custom field", with_ee: %i[calculated_values] do
      using CustomFieldFormulaReferencing

      shared_let(:project_custom_field_section) { create(:project_custom_field_section) }

      shared_let(:project1) { create(:project) }
      shared_let(:project2) { create(:project) }
      shared_let(:project3) { create(:project) }
      shared_let(:project4) { create(:project) }
      shared_let(:projects) { [project1, project2, project3, project4] }

      let(:common_attributes) do
        {
          type: custom_field_class.to_s,
          field_format: "calculated_value",
          name: "foo",
          custom_field_section_id: project_custom_field_section.id
        }
      end

      context "when creating not a calculated value" do
        let(:attributes) { { **common_attributes, field_format: "int" } }

        it "doesn't enqueue recalculation job" do
          expect { subject }.not_to have_enqueued_job(CustomFields::RecalculateValuesJob)
          expect(subject).to be_success
        end
      end

      context "when creating without is_required mark" do
        let(:attributes) { { **common_attributes, formula: "2 + 2" } }

        it "doesn't enqueue recalculation job" do
          expect { subject }.not_to have_enqueued_job(CustomFields::RecalculateValuesJob)
          expect(subject).to be_success
          expect(subject.result).to have_attributes(is_required: false)
        end
      end

      context "when creating with is_required mark" do
        let(:attributes) { { **common_attributes, formula: "2 + 2", is_required: true } }

        it "enqueues recalculation job" do
          expect(subject).to be_success
          expect(subject.result).to have_attributes(is_required: true)

          expect(CustomFields::RecalculateValuesJob)
            .to have_been_enqueued
            .with(user:, custom_field_id: subject.result.id)
        end
      end
    end
  end
end
