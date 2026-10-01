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
require "services/base_services/behaves_like_update_service"

RSpec.describe CustomFields::UpdateService, type: :model do
  it_behaves_like "BaseServices update service"

  describe "#call" do
    shared_let(:user) { create(:admin) }
    let(:contract_class) { CustomFields::UpdateContract }
    let(:contract_instance) { instance_double(contract_class, validate: true) }

    let(:instance) do
      described_class.new(user:,
                          model: custom_field,
                          contract_class:)
    end

    subject(:instance_call) { instance.call(attributes) }

    before do
      User.current = user
      allow(contract_class).to receive(:new).with(custom_field, user, options: {}).and_return(contract_instance)
    end

    describe "field_format attribute" do
      context "when trying to change it" do
        let!(:custom_field) { create(:boolean_wp_custom_field) }
        let(:attributes) { { field_format: "text" } }

        it "is ignored" do
          expect(subject).to be_success

          expect(custom_field.reload).to have_attributes(field_format: "bool")
        end
      end
    end

    describe "calculated value custom field", with_ee: %i[calculated_values] do
      using CustomFieldFormulaReferencing

      context "when updating not a calculated value" do
        let!(:custom_field) { create(:integer_project_custom_field) }
        let(:attributes) { { name: "foo" } }

        it "doesn't enqueue recalculation job" do
          expect { subject }.not_to have_enqueued_job(CustomFields::RecalculateValuesJob)
          expect(subject).to be_success
        end
      end

      context "when not updating formula of calculated value" do
        let!(:custom_field) { create(:calculated_value_project_custom_field) }
        let(:attributes) { { name: "foo" } }

        it "doesn't enqueue recalculation job" do
          expect { subject }.not_to have_enqueued_job(CustomFields::RecalculateValuesJob)
          expect(subject).to be_success
          expect(subject.result).to have_attributes(name: "foo")
        end
      end

      context "when updating formula of calculated value" do
        let!(:custom_field) { create(:calculated_value_project_custom_field, formula: "1 + 1") }
        let(:attributes) { { formula: "2 + 2" } }

        it "enqueues recalculation job" do
          expect { subject }
            .to have_enqueued_job(CustomFields::RecalculateValuesJob)
            .with(user:, custom_field_id: custom_field.id)

          expect(subject).to be_success
        end
      end

      context "when updating is_required of calculated value to false" do
        let!(:custom_field) { create(:calculated_value_project_custom_field, is_required: true) }
        let(:attributes) { { is_required: false } }

        it "doesn't enqueue recalculation job" do
          expect { subject }.not_to have_enqueued_job(CustomFields::RecalculateValuesJob)
          expect(subject).to be_success
          expect(subject.result).to have_attributes(is_required: false)
        end
      end

      context "when updating is_required of calculated value to true" do
        let!(:custom_field) { create(:calculated_value_project_custom_field, formula: "1 + 1") }
        let(:attributes) { { is_required: true } }

        it "enqueues recalculation job" do
          expect { subject }
            .to have_enqueued_job(CustomFields::RecalculateValuesJob)
            .with(user:, custom_field_id: custom_field.id)

          expect(subject).to be_success
          expect(subject.result).to have_attributes(is_required: true)
        end
      end
    end
  end
end
