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

RSpec.shared_context "with custom field params" do
  let(:cf1) { create(:work_package_custom_field, field_format: "text") }
  let(:cf2) { create(:work_package_custom_field, field_format: "text") }
  let!(:cf3) { create(:work_package_custom_field, field_format: "text") }

  let(:attribute_groups) do
    {
      attribute_groups: [
        { "type" => "attribute",
          "name" => "group1",
          "attributes" => [{ "key" => cf1.attribute_name }, { "key" => cf2.attribute_name }] },
        { "type" => "attribute",
          "name" => "groups",
          "attributes" => [{ "key" => cf2.attribute_name }] }
      ]
    }
  end

  let(:params) { attribute_groups }
end

RSpec.shared_examples_for "type service" do
  let(:success) { true }
  let(:params) { {} }
  let!(:contract) do
    instance_double(Types::BaseContract).tap do |contract|
      allow(contract)
        .to receive(:validate)
              .and_return(contract_valid)
      allow(contract)
        .to receive(:errors)
              .and_return(contract_errors)
      allow(Types::BaseContract)
        .to receive(:new)
              .and_return(contract)
    end
  end
  let(:contract_errors) { instance_double(ActiveModel::Errors) }
  let(:contract_valid) { success }

  describe "#call" do
    before do
      allow(type)
        .to receive(:save)
        .and_return(success)
    end

    it "is successful" do
      expect(service_call).to be_success
    end

    it "yields the block with success" do
      expect(service_call(&:success?)).to be_truthy
    end

    describe "with attributes" do
      let(:params) { { name: "blubs blubs" } }

      it "set the values provided on the call" do
        service_call

        expect(type.name).to eql params[:name]
      end
    end

    describe "attribute groups" do
      before do
        allow(type).to receive(:reset_attribute_groups)
        allow(type).to receive(:attribute_groups=)
      end

      context "when not given" do
        let(:params) { { name: "blubs blubs" } }

        it "set the values provided on the call" do
          service_call

          expect(type).not_to have_received(:reset_attribute_groups)
          expect(type).not_to have_received(:attribute_groups=)
          expect(type.name).to eql params[:name]
        end
      end

      context "when empty" do
        let(:params) { { attribute_groups: [] } }

        it "set the values provided on the call" do
          service_call

          expect(type).to have_received(:reset_attribute_groups)
          expect(type).not_to have_received(:attribute_groups=)
        end
      end

      context "when other" do
        let(:params) { { attribute_groups: [{ "type" => "attribute", "name" => "foo", "attributes" => [] }] } }

        it "set the values provided on the call" do
          service_call

          expect(type).not_to have_received(:reset_attribute_groups)
          expect(type).to have_received(:attribute_groups=)
        end
      end
    end

    describe "custom fields" do
      include_context "with custom field params"

      it "enables the custom fields that are passed via attribute_groups" do
        allow(type)
          .to receive(:work_package_attributes)
          .and_return(cf1.attribute_name => {}, cf2.attribute_name => {})

        allow(type)
          .to receive(:custom_field_ids=)
          .with([cf1.id, cf2.id])

        service_call

        expect(type).to have_received(:custom_field_ids=)
      end

      context "when all the projects are associated with the type" do
        before do
          type.projects = create_list :project, 2
        end

        it "enables the custom fields in the projects" do
          expect { service_call }
            .to change { Project.where(id: type.project_ids).map(&:work_package_custom_fields) }
            .from([[], []])
            .to([[cf1, cf2], [cf1, cf2]])
        end

        context "when a custom field is already associated with the type" do
          before do
            type.custom_field_ids = [cf1.id]
          end

          it "enables the new custom field only" do
            expect { service_call }
              .to change { Project.where(id: type.project_ids).map(&:work_package_custom_fields) }
              .from([[], []])
              .to([[cf2], [cf2]])
          end
        end

        context "when all custom fields are already associated with the type" do
          before do
            type.custom_field_ids = [cf1.id, cf2.id]
          end

          it "enables no custom field" do
            expect { service_call }
              .not_to change { Project.where(id: type.project_ids).map(&:work_package_custom_field_ids) }
              .from([[], []])
          end
        end
      end

      context "when a project is being set on the type" do
        let(:projects) { create_list(:project, 2) }
        let(:active_project) { projects.first }
        let(:project_ids) { { project_ids: [*projects.map { |p| p.id.to_s }, ""] } }
        let(:params) do
          attribute_groups.merge(project_ids)
        end

        before do
          type.projects << active_project
        end

        it "enables the custom fields for all the projects" do
          expect { service_call }
            .to change { Project.where(id: type.project_ids).map(&:work_package_custom_fields) }
            .from([[]])
            .to([[cf1, cf2], [cf1, cf2]])
        end

        context "when a custom field is already associated with the type" do
          before do
            type.custom_field_ids = [cf1.id]
          end

          it "enables the new cf for the existing project and enables both cfs for the new project" do
            expect { service_call }
              .to change { Project.where(id: type.project_ids).map(&:work_package_custom_fields) }
              .from([[]])
              .to([[cf2], [cf1, cf2]])
          end
        end

        context "when all custom fields are already associated with the type" do
          let(:params) { project_ids }

          before do
            type.custom_field_ids = [cf1.id, cf2.id]
          end

          it "enables the custom fields in the new project only" do
            expect { service_call }
              .to change { Project.where(id: type.project_ids).map(&:work_package_custom_fields) }
              .from([[]])
              .to([[], [cf1, cf2]])
          end
        end
      end
    end

    describe "query group" do
      let(:query_params) do
        sort_by = JSON::dump(["status:desc"])
        filters = JSON::dump([{ "status_id" => { "operator" => "=", "values" => %w(1 2) } }])

        { "sortBy" => sort_by, "filters" => filters }
      end
      let(:query_group_params) do
        { "type" => "query", "name" => "group1", "query" => JSON.dump(query_params) }
      end
      let(:params) { { attribute_groups: [query_group_params] } }
      let(:query) { Query.new }
      let(:service_result) { ServiceResult.success(result: query) }

      before do
        allow(Query)
          .to receive(:new_default)
          .with(name: "Embedded table: group1")
          .and_return(query)
      end

      it "assigns the fully parsed query to the type's attribute group with the system user as the querie's user" do
        expect(service_call).to be_success

        expect(type.attribute_groups[0].query)
          .to eql query

        expect(query.filters.length)
          .to be 1

        expect(query.filters[0].name)
          .to be :status_id

        expect(query.user)
          .to eq User.system
      end

      context "when the query parse service reports an error" do
        let(:success) { false }
        let(:service_result) { ServiceResult.failure(result: nil) }

        it "reports the error" do
          expect(service_call).to be_failure

          expect(type.attribute_groups[0].query)
            .to eql query
        end
      end
    end

    describe "on failure" do
      let(:success) { false }
      let(:params) { { name: nil } }

      subject { service_call }

      it "returns a failed service result" do
        expect(subject).not_to be_success
      end

      it "returns the errors of the type" do
        expect(subject.errors)
          .to eql contract_errors
      end

      describe "custom fields" do
        include_context "with custom field params"

        context "when the type is associated with projects" do
          before do
            type.projects = create_list :project, 2
          end

          it "does not changes project custom fields" do
            expect { service_call }
              .not_to change { Project.where(id: type.project_ids).map(&:work_package_custom_field_ids) }
              .from([[], []])
          end
        end
      end
    end
  end
end
