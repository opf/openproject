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

RSpec.describe API::V3::Grids::Schemas::GridSchemaRepresenter do
  include API::V3::Utilities::PathHelper

  let(:current_user) { build_stubbed(:user) }

  let(:self_link) { "/a/self/link" }
  let(:embedded) { true }
  let(:new_record) { true }
  let(:allowed_scopes) { %w(/some/path /some/other/path) }
  let(:allowed_widgets) do
    %w(first_widget second_widget)
  end
  let(:contract) do
    contract = double("contract")

    allow(contract)
      .to receive(:writable?) do |attribute|
      writable = %w(row_count column_count widgets)

      if new_record
        writable << "scope"
      end

      writable.include?(attribute.to_s)
    end

    allow(contract)
      .to receive(:assignable_values)
      .with(:scope, current_user)
      .and_return(allowed_scopes)

    allow(contract)
      .to receive(:assignable_widgets)
      .and_return(allowed_widgets)

    allow(contract)
      .to receive(:model)
      .and_return(double("model"))

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

    describe "rowCount" do
      let(:path) { "rowCount" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "Integer" }
        let(:name) { Grids::Grid.human_attribute_name(:row_count) }
        let(:required) { true }
        let(:writable) { true }
      end
    end

    describe "columnCount" do
      let(:path) { "columnCount" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "Integer" }
        let(:name) { Grids::Grid.human_attribute_name(:column_count) }
        let(:required) { true }
        let(:writable) { true }
      end
    end

    describe "createdAt" do
      let(:path) { "createdAt" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "DateTime" }
        let(:name) { Grids::Grid.human_attribute_name("created_at") }
        let(:required) { true }
        let(:writable) { false }
      end
    end

    describe "updatedAt" do
      let(:path) { "updatedAt" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "DateTime" }
        let(:name) { Grids::Grid.human_attribute_name("updated_at") }
        let(:required) { true }
        let(:writable) { false }
      end
    end

    describe "widgets" do
      let(:path) { "widgets" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "[]GridWidget" }
        let(:name) { Grids::Grid.human_attribute_name("widgets") }
        let(:required) { true }
        let(:writable) { true }
        let(:location) { "_links" }
      end

      context "when embedding" do
        let(:embedded) { true }

        it "contains no link to the allowed values" do
          expect(subject).not_to have_json_path("#{path}/_links/allowedValues")
        end

        it "embeds the allowed values" do
          allowed_widgets.each_with_index do |identifier, index|
            href_path = "#{path}/_embedded/allowedValues/#{index}/identifier"
            expect(subject).to be_json_eql(identifier.to_json).at_path(href_path)
          end
        end
      end

      context "when not embedding" do
        let(:embedded) { false }

        it_behaves_like "does not link to allowed values"
      end
    end

    describe "scope" do
      let(:path) { "scope" }

      context "when having a new record" do
        it_behaves_like "has basic schema properties" do
          let(:type) { "Href" }
          let(:name) { Grids::Grid.human_attribute_name("scope") }
          let(:required) { true }
          let(:writable) { true }
          let(:location) { "_links" }
        end

        context "when embedding" do
          let(:embedded) { true }

          it_behaves_like "links to allowed values directly" do
            let(:hrefs) { allowed_scopes }
          end

          it "does not embed" do
            expect(generated)
              .not_to have_json_path("scope/embedded")
          end
        end

        context "when not embedding" do
          let(:embedded) { false }

          it_behaves_like "does not link to allowed values"

          it "does not embed" do
            expect(generated)
              .not_to have_json_path("scope/embedded")
          end
        end
      end

      context "when not having a new record" do
        let(:new_record) { false }
        let(:allowed_scopes) { nil }

        it_behaves_like "has basic schema properties" do
          let(:type) { "Href" }
          let(:name) { Grids::Grid.human_attribute_name("scope") }
          let(:required) { true }
          let(:writable) { false }
          let(:location) { "_links" }
        end

        context "when embedding" do
          let(:embedded) { true }

          it_behaves_like "does not link to allowed values"

          it "does not embed" do
            expect(generated)
              .not_to have_json_path("scope/embedded")
          end
        end

        context "when not embedding" do
          let(:embedded) { false }

          it_behaves_like "does not link to allowed values"

          it "does not embed" do
            expect(generated)
              .not_to have_json_path("scope/embedded")
          end
        end
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
