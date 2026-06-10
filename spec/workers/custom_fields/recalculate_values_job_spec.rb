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

RSpec.describe CustomFields::RecalculateValuesJob, type: :model do
  describe "#perform", with_ee: %i[calculated_values] do
    using CustomFieldFormulaReferencing

    shared_let(:user) { create(:admin) }
    shared_let(:project1) { create(:project) }
    shared_let(:project2) { create(:project) }
    shared_let(:project3) { create(:project) }
    shared_let(:project4) { create(:project) }
    shared_let(:projects) { [project1, project2, project3, project4] }

    current_user { user }
    subject { described_class.perform_now(user:, custom_field_id:) }

    context "when custom field does not exist" do
      let(:custom_field_id) { 999999 }

      it "does nothing" do
        expect { subject }
          .not_to change { Project.pluck(:updated_at) }
      end
    end

    context "when custom field is not calculated value" do
      let!(:custom_field) { create(:integer_project_custom_field) }
      let(:custom_field_id) { custom_field.id }

      it "does nothing" do
        expect { subject }
          .not_to change { Project.pluck(:updated_at) }
      end
    end

    context "when custom field is calculated value" do
      context "and is not activated for all projects" do
        context "with formula referencing other fields" do
          let!(:static) { create(:integer_project_custom_field, projects:) }
          let!(:custom_field) do
            create(:calculated_value_project_custom_field,
                   projects: [project1, project2],
                   formula: "#{static} * 2")
          end
          let!(:custom_field2) do
            create(:calculated_value_project_custom_field,
                   projects: [project1, project3],
                   formula: "#{custom_field} * 10.5")
          end
          let(:custom_field_id) { custom_field.id }

          before do
            projects.each.with_index(1) do |project, i|
              # using update_columns to prevent auto enabling for the project
              create(:custom_value, customized: project, custom_field: static).update_columns(value: i)
              create(:custom_value, customized: project, custom_field: custom_field).update_columns(value: 0)
              create(:custom_value, customized: project, custom_field: custom_field2).update_columns(value: 0)
            end
          end

          it "updates calculated values on all objects that have the field enabled" do
            subject

            aggregate_failures do
              expect(project1.reload.custom_value_attributes(all: true))
                .to include(custom_field.id => "2", custom_field2.id => "21.0")
              expect(project2.reload.custom_value_attributes(all: true))
                .to include(custom_field.id => "4", custom_field2.id => "0")
              expect(project3.reload.custom_value_attributes(all: true))
                .to include(custom_field.id => "0", custom_field2.id => "0")
              expect(project4.reload.custom_value_attributes(all: true))
                .to include(custom_field.id => "0", custom_field2.id => "0")
            end
          end

          it "saves the objects when there are changes" do
            expect { subject }
              .to change { project1.reload.updated_at }
              .and change { project2.reload.updated_at }
              .and not_change { project3.reload.updated_at }
              .and(not_change { project4.reload.updated_at })
          end
        end
      end

      context "and is activated for all projects" do
        context "with a static formula" do
          let!(:custom_field) { create(:calculated_value_project_custom_field, formula: "1 + 1", is_for_all: true) }
          let(:custom_field_id) { custom_field.id }

          it "updates calculated values on all objects" do
            subject

            aggregate_failures do
              projects.each do |project|
                expect(project.reload.custom_value_attributes(all: true)).to include(custom_field.id => "2")
              end
            end
          end

          it "saves all objects" do
            expect { subject }
              .to change { project1.reload.updated_at }
              .and change { project2.reload.updated_at }
              .and change { project3.reload.updated_at }
              .and change { project4.reload.updated_at }
          end
        end

        context "with formula referencing other fields" do
          let!(:static) { create(:integer_project_custom_field, projects: [project1, project2, project3]) }
          let!(:custom_field) do
            create(:calculated_value_project_custom_field, formula: "#{static} * 3", is_for_all: true)
          end
          let(:custom_field_id) { custom_field.id }

          before do
            create(:custom_value, customized: project1, custom_field: static, value: 1)
            create(:custom_value, customized: project3, custom_field: static, value: 2)
          end

          it "updates calculated values on all objects that have the static field set" do
            subject

            aggregate_failures do
              expect(project1.reload.custom_value_attributes(all: true)).to include(custom_field.id => "3")
              expect(project2.reload.custom_value_attributes(all: true)).to include(custom_field.id => nil)
              expect(project3.reload.custom_value_attributes(all: true)).to include(custom_field.id => "6")
              expect(project4.reload.custom_value_attributes(all: true)).to include(custom_field.id => nil)
            end
          end

          it "saves all objects" do
            expect { subject }
              .to change { project1.reload.updated_at }
              .and change { project2.reload.updated_at }
              .and change { project3.reload.updated_at }
              .and change { project4.reload.updated_at }
          end
        end
      end
    end
  end
end
