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
require_relative "shared_contract_examples"

RSpec.describe Projects::UpdateContract do
  it_behaves_like "project contract" do
    let(:custom_field) do
      build_stubbed(:integer_project_custom_field).tap do |cf|
        cf.id = "1001"
        allow_any_instance_of(CustomValue) # rubocop:disable RSpec/AnyInstance
          .to receive(:custom_field).and_return(cf)
      end
    end

    let(:project) do
      build_stubbed(:project,
                    active: project_active,
                    public: project_public,
                    status_code: project_status_code,
                    status_explanation: project_status_explanation).tap do |p|
        allow(p).to receive_messages(available_custom_fields: [custom_field],
                                     all_available_custom_fields: [custom_field])
        next unless project_changed

        # in order to actually have something changed
        p.name = project_name
        p.parent = project_parent
        p.identifier = project_identifier
      end
    end
    let(:project_permissions) { %i(edit_project) }
    let(:project_changed) { true }
    let(:options) { {} }

    subject(:contract) { described_class.new(project, current_user, options:) }

    context "if the identifier is nil" do
      let(:project_identifier) { nil }

      it "is replaced for new project" do
        expect_valid(false, identifier: %i(blank))
      end
    end

    describe "permissions" do
      context "with edit_project_attributes" do
        let(:project_permissions) { %i(edit_project_attributes) }

        context "when project_attributes_only flag is true" do
          let(:options) { { project_attributes_only: true } }

          before do
            project.custom_field_values = { custom_field.id => "1" }
          end

          context "and only project_custom_fields are changed" do
            let(:project_changed) { false }

            it_behaves_like "is valid"
          end

          context "and other project attributes are changed too" do
            let(:project_changed) { true }

            it "is invalid" do
              expect_valid(false, { name: %i(error_readonly),
                                    parent_id: %i(error_readonly),
                                    identifier: %i(error_readonly) })
            end
          end
        end

        context "when project_attributes_only flag is false" do
          let(:options) { { project_attributes_only: false } }

          it "is invalid" do
            expect_valid(false, base: %i(error_unauthorized))
          end
        end
      end

      context "with edit_project" do
        context "when project_attributes_only flag is true" do
          let(:options) { { project_attributes_only: true } }

          it "is invalid" do
            expect_valid(false, base: %i(error_unauthorized))
          end
        end

        context "when project_attributes_only flag is false" do
          let(:options) { { project_attributes_only: false } }

          context "and only project attributes are changed" do
            let(:project_changed) { true }

            it_behaves_like "is valid"
          end

          context "and project_custom_fields are changed too" do
            let(:project_changed) { true }

            before do
              project.custom_field_values = { custom_field.id => "1" }
            end

            it "is invalid" do
              expect_valid(false, "custom_field_#{custom_field.id}": %i(error_readonly))
            end
          end
        end
      end

      context "with both edit_project and edit_project_attributes are set" do
        let(:project_permissions) { %i(edit_project edit_project_attributes) }

        context "when project_attributes_only flag is true" do
          let(:options) { { project_attributes_only: true } }

          context "and only project attributes are changed" do
            let(:project_changed) { true }

            it "is invalid" do
              expect_valid(false, { name: %i(error_readonly),
                                    parent_id: %i(error_readonly),
                                    identifier: %i(error_readonly) })
            end
          end

          context "and only project_custom_fields are changed" do
            let(:project_changed) { false }

            before do
              project.custom_field_values = { custom_field.id => "1" }
            end

            it_behaves_like "is valid"
          end

          context "when both project attributes and project custom_fields are changed" do
            let(:project_changed) { true }

            before do
              project.custom_field_values = { custom_field.id => "1" }
            end

            it "is invalid" do
              expect_valid(false, { name: %i(error_readonly),
                                    parent_id: %i(error_readonly),
                                    identifier: %i(error_readonly) })
            end
          end
        end

        context "when project_attributes_only flag is false" do
          let(:options) { { project_attributes_only: false } }

          context "and only project attributes are changed" do
            let(:project_changed) { true }

            it_behaves_like "is valid"
          end

          context "and project_custom_fields are changed too" do
            let(:project_changed) { true }

            before do
              project.custom_field_values = { custom_field.id => "1" }
            end

            it_behaves_like "is valid"
          end
        end
      end

      context "without permissions when project_attributes_only flag is true" do
        let(:project_permissions) { [] }
        let(:options) { { project_attributes_only: true } }

        it "is invalid" do
          expect_valid(false, base: %i(error_unauthorized))
        end
      end
    end

    describe "#writable_attributes" do
      let(:project_changed) { false }

      shared_examples "can write" do |attribute|
        it "can write #{attribute}" do
          expect(contract.writable_attributes).to include(attribute.to_s)
        end
      end

      shared_examples "can not write" do |attribute|
        it "can not write #{attribute}" do
          expect(contract.writable_attributes).not_to include(attribute.to_s)
        end
      end

      context "with edit_project_attributes" do
        let(:project_permissions) { %i(edit_project_attributes) }

        context "when project_attributes_only flag is true" do
          let(:options) { { project_attributes_only: true } }

          it_behaves_like "can write", :custom_field_1001
          it_behaves_like "can not write", :name
        end

        context "when project_attributes_only flag is false" do
          let(:options) { { project_attributes_only: false } }

          it_behaves_like "can write", :custom_field_1001
          it_behaves_like "can not write", :name
        end
      end

      context "with edit_project" do
        context "when project_attributes_only flag is true" do
          let(:options) { { project_attributes_only: true } }

          it_behaves_like "can not write", :custom_field_1001
          it_behaves_like "can not write", :name
        end

        context "when project_attributes_only flag is false" do
          let(:options) { { project_attributes_only: false } }

          it_behaves_like "can not write", :custom_field_1001, "1"
          it_behaves_like "can write", :name
        end
      end

      context "with both edit_project and edit_project_attributes are set" do
        let(:project_permissions) { %i(edit_project edit_project_attributes) }

        context "when project_attributes_only flag is true" do
          let(:options) { { project_attributes_only: true } }

          it_behaves_like "can write", :custom_field_1001
          it_behaves_like "can not write", :name
        end

        context "when project_attributes_only flag is false" do
          let(:options) { { project_attributes_only: false } }

          it_behaves_like "can write", :custom_field_1001
          it_behaves_like "can write", :name
        end
      end

      context "without permissions" do
        let(:project_permissions) { [] }

        context "when project_attributes_only flag is true" do
          let(:options) { { project_attributes_only: true } }

          it_behaves_like "can not write", :custom_field_1001
          it_behaves_like "can not write", :name
        end

        context "when project_attributes_only flag is false" do
          let(:options) { { project_attributes_only: false } }

          it_behaves_like "can not write", :custom_field_1001
          it_behaves_like "can not write", :name
        end
      end
    end
  end
end
