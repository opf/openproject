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

RSpec.describe API::V3::Versions::Schemas::VersionSchemaRepresenter do
  include API::V3::Utilities::PathHelper

  let(:current_user) { build_stubbed(:user) }

  let(:self_link) { "/a/self/link" }
  let(:embedded) { true }
  let(:new_record) { true }
  let(:allowed_sharings) { %w(tree system) }
  let(:allowed_status) { %w(open fixed closed) }
  let(:custom_field) do
    build_stubbed(:version_custom_field, :integer)
  end
  let(:version) { build_stubbed(:version) }

  let(:contract) do
    contract = instance_double(new_record ? Versions::CreateContract : Versions::UpdateContract,
                               new_record?: new_record,
                               model: version)

    allow(contract)
      .to receive(:writable?) do |attribute|
      writable = %w(name description start_date due_date status sharing)

      if new_record
        writable << "project"
      end

      writable.include?(attribute.to_s)
    end

    allow(contract)
      .to receive(:assignable_values)
      .with(:status, current_user)
      .and_return(allowed_status)

    allow(contract)
      .to receive(:assignable_values)
      .with(:sharing, current_user)
      .and_return(allowed_sharings)

    allow(contract)
      .to receive(:available_custom_fields)
      .and_return([custom_field])

    contract
  end
  let(:representer) do
    described_class.create(contract,
                           self_link:,
                           form_embedded: embedded,
                           current_user:)
  end

  context "generation" do
    subject(:generated) { representer.to_json }

    describe "_type" do
      it "is indicated as Schema" do
        expect(subject).to be_json_eql("Schema".to_json).at_path("_type")
      end
    end

    describe "id" do
      let(:path) { "id" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "Integer" }
        let(:name) { I18n.t("attributes.id") }
        let(:required) { true }
        let(:writable) { false }
      end
    end

    describe "createdAt" do
      let(:path) { "createdAt" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "DateTime" }
        let(:name) { Version.human_attribute_name("created_at") }
        let(:required) { true }
        let(:writable) { false }
      end
    end

    describe "updatedAt" do
      let(:path) { "updatedAt" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "DateTime" }
        let(:name) { Version.human_attribute_name("updated_at") }
        let(:required) { true }
        let(:writable) { false }
      end
    end

    describe "name" do
      let(:path) { "name" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "String" }
        let(:name) { Version.human_attribute_name("name") }
        let(:required) { true }
        let(:writable) { true }
      end

      it_behaves_like "indicates length requirements" do
        let(:min_length) { 1 }
        let(:max_length) { 60 }
      end
    end

    describe "description" do
      let(:path) { "description" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "Formattable" }
        let(:name) { Version.human_attribute_name("description") }
        let(:required) { false }
        let(:writable) { true }
      end
    end

    describe "int custom field" do
      let(:path) { custom_field.attribute_name(:camel_case) }

      it_behaves_like "has basic schema properties" do
        let(:type) { "Integer" }
        let(:name) { custom_field.name }
        let(:required) { false }
        let(:writable) { false }
      end
    end

    describe "startDate" do
      let(:path) { "startDate" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "Date" }
        let(:name) { Version.human_attribute_name("start_date") }
        let(:required) { false }
        let(:writable) { true }
      end
    end

    describe "endDate" do
      let(:path) { "endDate" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "Date" }
        let(:name) { Version.human_attribute_name("due_date") }
        let(:required) { false }
        let(:writable) { true }
      end
    end

    describe "definingProject" do
      let(:path) { "definingProject" }

      context "if having a new record" do
        it_behaves_like "has basic schema properties" do
          let(:type) { "Project" }
          let(:name) { Version.human_attribute_name("project") }
          let(:required) { true }
          let(:writable) { true }
          let(:location) { "_links" }
        end

        context "if embedding" do
          let(:embedded) { true }

          it_behaves_like "links to allowed values via collection link" do
            let(:href) do
              api_v3_paths.versions_available_projects
            end
          end
        end

        context "if not embedding" do
          let(:embedded) { false }

          it_behaves_like "does not link to allowed values"
        end
      end

      context "if having a persisted record" do
        let(:new_record) { false }

        it_behaves_like "has basic schema properties" do
          let(:type) { "Project" }
          let(:name) { Version.human_attribute_name("project") }
          let(:required) { true }
          let(:writable) { false }
          let(:location) { "_links" }
        end

        context "if embedding" do
          let(:embedded) { true }

          it_behaves_like "does not link to allowed values"
        end
      end
    end

    describe "status" do
      let(:path) { "status" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "String" }
        let(:name) { Version.human_attribute_name("status") }
        let(:required) { true }
        let(:writable) { true }
        let(:location) { "_links" }
      end

      it "contains no link to the allowed values" do
        expect(subject)
          .not_to have_json_path("#{path}/_links/allowedValues")
      end

      it "embeds the allowed values" do
        allowed_path = "#{path}/_embedded/allowedValues"

        expect(subject)
          .to be_json_eql(allowed_status.to_json)
          .at_path(allowed_path)
      end
    end

    describe "sharing" do
      let(:path) { "sharing" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "String" }
        let(:name) { Version.human_attribute_name("sharing") }
        let(:required) { true }
        let(:writable) { true }
        let(:location) { "_links" }
      end

      it "contains no link to the allowed values" do
        expect(subject)
          .not_to have_json_path("#{path}/_links/allowedValues")
      end

      it "embeds the allowed values" do
        allowed_path = "#{path}/_embedded/allowedValues"

        expect(subject)
          .to be_json_eql(allowed_sharings.to_json)
          .at_path(allowed_path)
      end
    end

    context "_links" do
      describe "self link" do
        it_behaves_like "has an untitled link" do
          let(:link) { "self" }
          let(:href) { self_link }
        end

        context "embedded in a form" do
          let(:self_link) { nil }

          it_behaves_like "has no link" do
            let(:link) { "self" }
          end
        end
      end
    end
  end
end
