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

RSpec.describe WorkPackageTypes::PatternResolver do
  let(:subject_pattern) { "ID Please: {{id}}" }

  shared_let(:work_package) { create(:work_package, remaining_hours: 2) }

  subject(:resolver) { described_class.new(subject_pattern) }

  it "resolves a pattern" do
    expect(subject.resolve(work_package)).to eq("ID Please: #{work_package.id}")
  end

  context "when the pattern has WorkPackage properties" do
    let(:subject_pattern) { "{{id}} | {{author}} | {{creation_date}}" }

    it "resolves the pattern" do
      expect(subject.resolve(work_package))
        .to eq("#{work_package.id} | #{work_package.author} | #{work_package.created_at.to_date.iso8601}")
    end
  end

  context "when the pattern has WorkPackage association attributes" do
    let(:subject_pattern) { "{{id}} | {{author}} | {{type}}" }

    it "resolves the pattern" do
      expect(subject.resolve(work_package))
        .to eq("#{work_package.id} | #{work_package.author.name} | #{work_package.type.name}")
    end
  end

  context "when the pattern has attributes that do not resolve to a value" do
    let(:subject_pattern) { "{{invalid_attribute}} | empty: {{assignee}} | without parent: {{parent_subject}}" }

    it "resolves the pattern" do
      expect(subject.resolve(work_package)).to eq("N/A | empty: [Assignee] | without parent: N/A")
    end
  end

  context "when the pattern has observed in versions" do
    let(:subject_pattern) { "Observed in: {{observed_in_versions}}" }

    let(:observed_version) { create(:version, project: work_package.project, name: "1.0") }

    before do
      create(:work_package_version, work_package:, version: observed_version, kind: :observed_in)
    end

    it "resolves the pattern" do
      expect(subject.resolve(work_package)).to eq("Observed in: 1.0")
    end
  end

  context "when the pattern has time attributes" do
    let(:subject_pattern) { "Time left: {{remaining_time}}" }

    it "resolves the pattern" do
      expect(subject.resolve(work_package)).to eq("Time left: 2h")
    end
  end

  context "when the pattern has custom fields" do
    let(:custom_field) { create(:string_wp_custom_field) }
    let(:multi_value_field) { create(:multi_list_wp_custom_field) }
    let(:custom_field_not_configured) { create(:string_wp_custom_field) }
    let(:type) { create(:type).tap { |t| t.default_variant.update!(custom_fields: [custom_field, multi_value_field]) } }
    let(:project) { create(:project, types: [type], work_package_custom_fields: [custom_field, multi_value_field]) }
    let(:project_custom_field) { create(:project_custom_field, projects: [project], field_format: "string") }

    let(:subject_pattern) do
      "{{project_custom_field_#{project_custom_field.id}}} A custom field value: {{custom_field_#{custom_field.id}}}"
    end

    let(:work_package) do
      create(:work_package, type:, project:,
                            custom_values: { custom_field.id => "Important Information",
                                             multi_value_field.id => multi_value_field.possible_values.take(2) })
    end

    before do
      project.public_send :"custom_field_#{project_custom_field.id}=", "PROSPEC"
      project.save
    end

    it "multi value fields are joined by comma" do
      subject_pattern = "MCF: {{custom_field_#{multi_value_field.id}}}"
      resolver = described_class.new(subject_pattern)
      expect(resolver.resolve(work_package)).to eq("MCF: A, B")
    end

    it "resolves the pattern" do
      User.current = SystemUser.first

      expect(subject.resolve(work_package)).to eq("PROSPEC A custom field value: Important Information")
    end

    context "if the pattern contains custom fields that are not configured" do
      let(:subject_pattern) { "pattern: {{invalid_attribute}}" }

      it "resolves the pattern" do
        expect(subject.resolve(work_package)).to eq("pattern: N/A")
      end
    end
  end

  context "when the type links its form configuration to a source type", with_flag: { type_variants: true } do
    let(:source_cf) { create(:string_wp_custom_field) }
    let(:source_type) { create(:type).tap { |t| t.default_variant.update!(custom_fields: [source_cf]) } }
    let(:linked_type) { create(:type) }
    let(:project) { create(:project, types: [linked_type], work_package_custom_fields: [source_cf]) }
    let(:subject_pattern) { "CF: {{custom_field_#{source_cf.id}}}" }

    let(:work_package) do
      create(:work_package, type: linked_type, project:, custom_values: { source_cf.id => "Borrowed Value" })
    end

    before do
      link_configuration(linked_type.default_variant, source: source_type.default_variant, aspect: TypeVariant::FORM_CONFIGURATION)
    end

    it "resolves the custom field token via the linked source type" do
      expect(subject.resolve(work_package)).to eq("CF: Borrowed Value")
    end
  end
end
