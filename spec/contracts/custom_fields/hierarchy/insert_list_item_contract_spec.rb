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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe CustomFields::Hierarchy::InsertListItemContract do
  subject { described_class.new }

  # rubocop:disable Rails/DeprecatedActiveModelErrorsMethods
  describe "#call" do
    let(:parent) { create(:hierarchy_item) }

    context "when all required fields are valid" do
      let(:params) { { parent:, label: "Valid Label", short: nil } }

      it "is valid" do
        result = subject.call(params)
        expect(result).to be_success
      end
    end

    context "when parent is not of type 'Item'" do
      let(:invalid_parent) { create(:custom_field) }
      let(:params) { { parent: invalid_parent, label: "Valid Label", short: nil } }

      it "is invalid" do
        result = subject.call(params)
        expect(result).to be_failure
        expect(result.errors.to_h).to include(parent: ["must be CustomField::Hierarchy::Item."])
      end
    end

    context "when label is not unique within the same hierarchy level" do
      before do
        create(:hierarchy_item, parent:, label: "Duplicate Label")
      end

      let(:params) { { parent:, label: "Duplicate Label", short: nil } }

      it "is invalid" do
        result = subject.call(params)
        expect(result).to be_failure
        expect(result.errors.to_h).to include(label: ["must be unique within the same hierarchy level."])
      end

      context "if another locale is set" do
        let(:mordor) { "agh burzum-ishi krimpatul" }

        before do
          I18n.config.enforce_available_locales = false
          I18n.backend.store_translations(
            :mo,
            { op_dry_validation: {
              errors: { rules: { label: { not_unique: mordor } } }
            } }
          )
        end

        after do
          I18n.config.enforce_available_locales = true
        end

        it "is invalid with localized validation errors" do
          I18n.with_locale(:mo) do
            result = subject.call(params)
            expect(result).to be_failure
            expect(result.errors.to_h).to include(label: [mordor])
          end
        end
      end
    end

    context "when the label only differs in case from a label in the same hierarchy level" do
      let(:params) { { parent:, label: "duplicate LABEL", short: nil } }

      before { create(:hierarchy_item, parent:, label: "Duplicate Label") }

      it "is invalid" do
        expect(subject.call(params).errors.to_h).to include(label: ["must be unique within the same hierarchy level."])
      end
    end

    context "when short is not unique in the same hierarchy level" do
      let(:params) { { parent:, label: "Valid Label", short: "Repeated Short" } }

      before { create(:hierarchy_item, parent:, label: "Unique Label", short: "Repeated Short") }

      it "is invalid with localized validation errors" do
        result = subject.call(params)
        expect(result).to be_failure
        expect(result.errors.to_h).to include(short: ["must be unique within the same hierarchy level."])
      end
    end

    context "when the short only differs in case from a short in the same hierarchy level" do
      let(:params) { { parent:, label: "Valid Label", short: "repeated SHORT" } }

      before { create(:hierarchy_item, parent:, label: "Unique Label", short: "Repeated Short") }

      it "is invalid" do
        expect(subject.call(params).errors.to_h).to include(short: ["must be unique within the same hierarchy level."])
      end
    end

    context "when short is set and is a string" do
      let(:params) { { parent:, label: "Valid Label", short: "Valid Short" } }

      it "is valid" do
        result = subject.call(params)
        expect(result).to be_success
      end
    end

    context "when short is set and is not a string" do
      let(:params) { { parent:, label: "Valid Label", short: 123 } }

      it "is invalid" do
        result = subject.call(params)
        expect(result).to be_failure
        expect(result.errors.to_h).to include(short: ["must be a string."])
      end
    end

    context "when inputs are valid" do
      it "creates a success result" do
        [
          { parent:, label: "A label", short: "A shorthand" },
          { parent:, label: "A label", short: nil }
        ].each { |params| expect(subject.call(params)).to be_success }
      end
    end

    context "with a project", with_ee: %i[custom_field_hierarchies] do
      let(:custom_field) { create(:custom_field, :hierarchy, allow_additional_project_values: true) }
      let(:parent) { custom_field.hierarchy_root }
      let(:project) { create(:project) }
      let(:other_project) { create(:project) }
      let(:params) { { parent:, label: "Project Label", short: "PL", project: } }

      it "is valid" do
        expect(subject.call(params)).to be_success
      end

      context "when the custom field does not allow additional project values" do
        let(:custom_field) { create(:custom_field, :hierarchy, allow_additional_project_values: false) }

        it "is invalid" do
          result = subject.call(params)
          expect(result).to be_failure
          expect(result.errors.to_h).to include(project: ["cannot add values to this custom field."])
        end
      end

      context "when the parent belongs to the same project" do
        let(:params) { { parent: create(:hierarchy_item, parent:, project:), label: "Project Label", short: nil, project: } }

        it "is valid" do
          expect(subject.call(params)).to be_success
        end
      end

      context "when the parent belongs to another project" do
        let(:params) do
          { parent: create(:hierarchy_item, parent:, project: other_project), label: "Project Label", short: nil, project: }
        end

        it "is invalid" do
          result = subject.call(params)
          expect(result).to be_failure
          expect(result.errors.to_h).to include(parent: ["must be a global value or belong to the same project."])
        end
      end

      context "when a global sibling uses the label" do
        before { create(:hierarchy_item, parent:, label: "Project Label") }

        it "is invalid" do
          expect(subject.call(params).errors.to_h).to include(label: ["must be unique within the same hierarchy level."])
        end
      end

      context "when a global sibling uses the label in a different case" do
        before { create(:hierarchy_item, parent:, label: "PROJECT LABEL") }

        it "is invalid" do
          expect(subject.call(params).errors.to_h).to include(label: ["must be unique within the same hierarchy level."])
        end
      end

      context "when a global sibling uses the short" do
        before { create(:hierarchy_item, parent:, label: "Global Label", short: "PL") }

        it "is invalid" do
          expect(subject.call(params).errors.to_h).to include(short: ["must be unique within the same hierarchy level."])
        end
      end

      context "when a global sibling uses the short in a different case" do
        before { create(:hierarchy_item, parent:, label: "Global Label", short: "pl") }

        it "is invalid" do
          expect(subject.call(params).errors.to_h).to include(short: ["must be unique within the same hierarchy level."])
        end
      end

      context "when a sibling of the same project uses the label" do
        before { create(:hierarchy_item, parent:, label: "Project Label", project:) }

        it "is invalid" do
          expect(subject.call(params).errors.to_h).to include(label: ["must be unique within the same hierarchy level."])
        end
      end

      context "when a sibling of the same project uses the label in a different case" do
        before { create(:hierarchy_item, parent:, label: "project label", project:) }

        it "is invalid" do
          expect(subject.call(params).errors.to_h).to include(label: ["must be unique within the same hierarchy level."])
        end
      end

      context "when a sibling of another project uses the label and short" do
        before { create(:hierarchy_item, parent:, label: "Project Label", short: "PL", project: other_project) }

        it "is valid" do
          expect(subject.call(params)).to be_success
        end
      end

      context "when a sibling of another project uses the label and short in a different case" do
        before { create(:hierarchy_item, parent:, label: "project label", short: "pl", project: other_project) }

        it "is valid" do
          expect(subject.call(params)).to be_success
        end
      end
    end

    context "with a global item", with_ee: %i[custom_field_hierarchies] do
      let(:custom_field) { create(:custom_field, :hierarchy, allow_additional_project_values: true) }
      let(:root) { custom_field.hierarchy_root }
      let(:project) { create(:project) }

      context "when a project sibling uses the label" do
        let(:params) { { parent: root, label: "Project Label", short: nil } }

        before { create(:hierarchy_item, parent: root, label: "Project Label", project:) }

        it "is invalid" do
          expect(subject.call(params).errors.to_h).to include(label: ["must be unique within the same hierarchy level."])
        end
      end

      context "when a project sibling uses the label in a different case" do
        let(:params) { { parent: root, label: "Project Label", short: nil } }

        before { create(:hierarchy_item, parent: root, label: "PROJECT label", project:) }

        it "is invalid" do
          expect(subject.call(params).errors.to_h).to include(label: ["must be unique within the same hierarchy level."])
        end
      end

      context "when the parent belongs to a project" do
        let(:params) { { parent: create(:hierarchy_item, parent: root, project:), label: "Global Label", short: nil } }

        it "is invalid" do
          expect(subject.call(params).errors.to_h).to include(parent: ["must be a global value or belong to the same project."])
        end
      end
    end

    context "when inputs are invalid" do
      it "creates a failure result" do
        [
          { parent: },
          { parent:, label: "A label" },
          { parent:, short: "AL" },
          { parent: nil, label: "A label", short: nil },
          { parent: 42, label: "A label", short: nil },
          { parent:, label: nil, short: nil },
          { parent:, label: 42, short: nil },
          { parent:, label: "A label", short: 42 }
        ].each { |params| expect(subject.call(params)).to be_failure }
      end
    end
  end
  # rubocop:enable Rails/DeprecatedActiveModelErrorsMethods
end
