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

RSpec.describe Type::ConfigurationLink do
  describe "aspect enum" do
    it "is string-backed with the configured aspects" do
      expect(subject).to define_enum_for(:aspect)
        .with_values(
          pdf_export: "pdf_export",
          patterns: "patterns",
          workflows: "workflows",
          automations: "automations",
          projects: "projects",
          form_configuration: "form_configuration"
        )
        .backed_by_column_of_type(:string)
    end

    it "exposes the aspect identifiers as constants" do
      expect(described_class::ASPECTS)
        .to contain_exactly(described_class::PDF_EXPORT, described_class::PATTERNS,
                            described_class::WORKFLOWS, described_class::AUTOMATIONS,
                            described_class::PROJECTS, described_class::FORM_CONFIGURATION)
    end

    it "links only the aspects whose linked behaviour is implemented to the parent by default" do
      expect(described_class::DEFAULT_PARENT_LINK_ASPECTS)
        .to contain_exactly(described_class::PDF_EXPORT, described_class::PATTERNS)
    end

    it "rejects an unknown aspect" do
      link = build(:type_configuration_link, aspect: "nonsense")

      expect(link).not_to be_valid
    end
  end

  describe "associations" do
    it "links a type to the source type it borrows from" do
      type = create(:type)
      source = create(:type)
      link = create(:type_configuration_link, type:, source:, aspect: described_class::PATTERNS)

      expect(link.type).to eq(type)
      expect(link.source).to eq(source)
    end
  end

  describe "validations" do
    let(:type) { create(:type) }

    it "requires a source" do
      link = build(:type_configuration_link, type:, source: nil, aspect: described_class::PATTERNS)

      expect(link).not_to be_valid
    end

    it "rejects a link whose source is the type itself" do
      link = build(:type_configuration_link, type:, source: type, aspect: described_class::PATTERNS)

      expect(link).not_to be_valid
    end
  end

  describe "uniqueness of (type, aspect)" do
    let(:type) { create(:type) }
    let(:source) { create(:type) }

    before { create(:type_configuration_link, type:, source:, aspect: described_class::PDF_EXPORT) }

    it "forbids a second link for the same type and aspect" do
      duplicate = build(:type_configuration_link, type:, source:, aspect: described_class::PDF_EXPORT)

      expect(duplicate).not_to be_valid
    end

    it "allows the other aspect to coexist for the same type" do
      other = build(:type_configuration_link, type:, source:, aspect: described_class::PATTERNS)

      expect(other).to be_valid
    end
  end
end
