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

RSpec.describe Projects::SetAttributesService, type: :model do
  let(:user) { build_stubbed(:user) }
  let(:contract_class) do
    contract = class_double(Projects::CreateContract)

    allow(contract)
      .to receive(:new)
      .with(project, user, options: {})
      .and_return(contract_instance)

    contract
  end
  let(:contract_instance) do
    instance_double(Projects::CreateContract, validate: contract_valid, errors: contract_errors)
  end
  let(:contract_valid) { true }
  let(:contract_errors) do
    instance_double(ActiveModel::Errors)
  end
  let(:project_valid) { true }
  let(:instance) do
    described_class.new(user:,
                        model: project,
                        contract_class:)
  end
  let(:call_attributes) { {} }
  let(:project) do
    build_stubbed(:project)
  end

  describe "call" do
    let(:call_attributes) do
      {}
    end

    before do
      allow(project)
        .to receive(:valid?)
        .and_return(project_valid)

      allow(contract_instance)
        .to receive(:validate)
        .and_return(contract_valid)
    end

    subject { instance.call(call_attributes) }

    it "is successful" do
      expect(subject).to be_success
    end

    it "calls validation" do
      subject

      expect(contract_instance)
        .to have_received(:validate)
    end

    it "sets the attributes" do
      subject

      expect(project.attributes.slice(*project.changed).symbolize_keys)
        .to eql call_attributes
    end

    it "does not persist the project" do
      allow(project)
        .to receive(:save)

      subject

      expect(project)
        .not_to have_received(:save)
    end

    shared_examples "setting status attributes" do
      let(:status_explanation) { "A magic dwells in each beginning." }

      it "sets the project status code" do
        expect(subject.result.status_code)
          .to eq status_code
      end

      it "sets the project status explanation" do
        expect(subject.result.status_explanation)
          .to eq status_explanation
      end
    end

    context "for a new record" do
      let(:project) do
        Project.new
      end

      describe "identifier default value" do
        context "with an identifier provided" do
          let(:call_attributes) do
            {
              identifier: "lorem"
            }
          end

          it "does not alter the identifier" do
            expect(subject.result.identifier)
              .to eql "lorem"
          end
        end
      end

      describe "public default value", with_settings: { default_projects_public: true } do
        context "with a value for is_public provided" do
          let(:call_attributes) do
            {
              public: false
            }
          end

          it "does not alter the public value" do
            expect(subject.result)
              .not_to be_public
          end
        end

        context "with no value for public provided" do
          it "sets uses the default value" do
            expect(subject.result)
              .to be_public
          end
        end
      end

      describe "enabled_module_names default value", with_settings: { default_projects_modules: ["lorem", "ipsum"] } do
        context "with a value for enabled_module_names provided" do
          let(:call_attributes) do
            {
              enabled_module_names: %w(some other)
            }
          end

          it "does not alter the enabled modules" do
            expect(subject.result.enabled_module_names)
              .to match_array %w(some other)
          end
        end

        context "with no value for enabled_module_names provided" do
          it "sets a default enabled modules" do
            expect(subject.result.enabled_module_names)
              .to match_array %w(lorem ipsum)
          end
        end

        context "with the enabled modules being set before" do
          before do
            project.enabled_module_names = %w(some other)
          end

          it "does not alter the enabled modules" do
            expect(subject.result.enabled_module_names)
              .to match_array %w(some other)
          end
        end
      end

      describe "types default value" do
        let(:other_types) do
          [build_stubbed(:type)]
        end
        let(:default_types) do
          [build_stubbed(:type)]
        end

        before do
          allow(Type)
            .to receive(:default)
                  .and_return default_types
        end

        shared_examples "setting custom field defaults" do
          context "with custom fields" do
            let!(:custom_field) { create(:text_wp_custom_field, types:) }
            let!(:custom_field_with_no_type) { create(:text_wp_custom_field) }

            it "activates the type's custom fields" do
              expect(subject.result.work_package_custom_fields)
                .to eq([custom_field])
            end
          end
        end

        context "with a value for types provided" do
          let(:call_attributes) do
            {
              types: other_types
            }
          end

          it "does not alter the types" do
            expect(subject.result.types)
              .to match_array other_types
          end

          include_examples "setting custom field defaults" do
            let(:other_types) { [create(:type)] }
            let(:types) { other_types }
          end
        end

        context "with no value for types provided" do
          it "sets the default types" do
            expect(subject.result.types)
              .to match_array default_types
          end

          include_examples "setting custom field defaults" do
            let(:default_types) { [create(:type)] }
            let(:types) { default_types }
          end
        end

        context "with the types being set before" do
          let(:types) { [build(:type, name: "lorem")] }

          before do
            project.types = types
          end

          it "does not alter the types modules" do
            expect(subject.result.types.map(&:name))
              .to match_array %w(lorem)
          end

          include_examples "setting custom field defaults" do
            let(:types) { [create(:type, name: "lorem")] }
          end
        end
      end

      describe "project status" do
        context "with valid status attributes" do
          let(:status_code) { "on_track" }
          let(:call_attributes) do
            {
              status_code:,
              status_explanation:
            }
          end

          include_examples "setting status attributes"
        end

        context "with an invalid status code provided" do
          let(:status_code) { "wrong" }
          let(:call_attributes) do
            {
              status_code:,
              status_explanation:
            }
          end

          include_examples "setting status attributes"
        end
      end
    end

    context "for an existing project" do
      describe "project status" do
        let(:project) do
          build_stubbed(:project, :with_status)
        end

        context "with a value provided" do
          let(:status_code) { "at_risk" }
          let(:status_explanation) { "Still some magic there." }
          let(:call_attributes) do
            {
              status_code:,
              status_explanation:
            }
          end

          include_examples "setting status attributes"
        end
      end
    end
  end
end
