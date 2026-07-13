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

RSpec.describe Type::ConfigurationLinkable do
  let(:type) { create(:type) }
  let(:source) { create(:type) }
  let(:aspect) { Type::ConfigurationLink::PATTERNS }

  describe "#linked? and #source_for" do
    it "reports Independent (no link) by default" do
      expect(type).not_to be_linked(aspect)
      expect(type.source_for(aspect)).to be_nil
    end

    it "reports Linked once a link exists" do
      type.link!(aspect, source:)

      expect(type).to be_linked(aspect)
      expect(type.source_for(aspect)).to eq(source)
    end

    it "tracks each aspect independently" do
      type.link!(Type::ConfigurationLink::PATTERNS, source:)

      expect(type).to be_linked(Type::ConfigurationLink::PATTERNS)
      expect(type).not_to be_linked(Type::ConfigurationLink::PDF_EXPORT)
    end
  end

  describe "#link!" do
    it "re-points an existing link rather than creating a duplicate" do
      other_source = create(:type)
      type.link!(aspect, source:)

      expect { type.link!(aspect, source: other_source) }
        .not_to change { type.configuration_links.where(aspect:).count }.from(1)
      expect(type.source_for(aspect)).to eq(other_source)
    end
  end

  describe "#make_independent!" do
    it "removes the link for that aspect only" do
      type.link!(Type::ConfigurationLink::PATTERNS, source:)
      type.link!(Type::ConfigurationLink::PDF_EXPORT, source:)

      type.make_independent!(Type::ConfigurationLink::PATTERNS)

      expect(type).not_to be_linked(Type::ConfigurationLink::PATTERNS)
      expect(type).to be_linked(Type::ConfigurationLink::PDF_EXPORT)
    end

    it "adopts the source's configuration before severing when given a source" do
      configured = create(:type, patterns: { subject: { blueprint: "Adopted {{id}}", enabled: true } })
      type.link!(Type::ConfigurationLink::PATTERNS, source:)

      type.make_independent!(Type::ConfigurationLink::PATTERNS, source: configured)

      expect(type).not_to be_linked(Type::ConfigurationLink::PATTERNS)
      expect(type.reload.patterns.subject.blueprint).to eq("Adopted {{id}}")
    end
  end

  describe "sub-type default parent links" do
    it "links the default aspects to the parent when a sub-type is created" do
      parent = create(:type)
      child = create(:type, parent:)

      expect(child.source_for(Type::ConfigurationLink::PDF_EXPORT)).to eq(parent)
      expect(child.source_for(Type::ConfigurationLink::PATTERNS)).to eq(parent)
    end

    it "leaves the not-yet-implemented aspects Independent" do
      child = create(:type, parent: create(:type))

      expect(child).not_to be_linked(Type::ConfigurationLink::WORKFLOWS)
      expect(child).not_to be_linked(Type::ConfigurationLink::AUTOMATIONS)
      expect(child).not_to be_linked(Type::ConfigurationLink::PROJECTS)
      expect(child).not_to be_linked(Type::ConfigurationLink::FORM_CONFIGURATION)
    end

    it "leaves a root type Independent for all aspects" do
      root = create(:type)

      Type::ConfigurationLink::ASPECTS.each do |aspect|
        expect(root).not_to be_linked(aspect)
      end
    end
  end

  describe "deletion" do
    it "destroys the type's own links when the type is destroyed" do
      type.link!(aspect, source:)

      type.destroy

      expect(Type::ConfigurationLink.where(type_id: type.id)).to be_empty
    end

    it "prevents destroying a type that is still a source for another type" do
      type.link!(aspect, source:)

      expect(source.destroy).to be_falsey
      expect(source.errors[:base]).to be_present
    end
  end

  describe "#effective_source_for", with_flag: { subtypes: true } do
    it "returns itself when Independent" do
      expect(type.effective_source_for(aspect)).to eq(type)
    end

    it "walks the link chain to the owning Independent type" do
      owner = create(:type)
      middle = create(:type)
      middle.link!(aspect, source: owner)
      type.link!(aspect, source: middle)

      expect(type.effective_source_for(aspect)).to eq(owner)
    end

    it "terminates on a cycle instead of looping forever" do
      other = create(:type)
      type.link!(aspect, source: other)
      other.link!(aspect, source: type)

      expect { type.effective_source_for(aspect) }.not_to raise_error
    end
  end

  describe "effective configuration", with_flag: { subtypes: true } do
    let(:owner) { create(:type, patterns: { subject: { blueprint: "X {{id}}", enabled: true } }) }

    it "resolves patterns from the linked owner" do
      type.link!(Type::ConfigurationLink::PATTERNS, source: owner)

      expect(type.effective_patterns.subject.blueprint).to eq("X {{id}}")
    end

    it "resolves its own patterns when Independent" do
      expect(type.effective_patterns).to eq(type.patterns)
    end
  end

  describe "#enabled_patterns and #replacement_pattern_defined_for?", with_flag: { subtypes: true } do
    let(:owner) { create(:type, patterns: { subject: { blueprint: "X {{id}}", enabled: true } }) }

    it "resolves the subject pattern from the linked owner" do
      type.link!(Type::ConfigurationLink::PATTERNS, source: owner)

      expect(type.enabled_patterns.keys).to include(:subject)
      expect(type).to be_replacement_pattern_defined_for(:subject)
    end

    it "reports no subject pattern when Independent and none is set" do
      expect(type).not_to be_replacement_pattern_defined_for(:subject)
    end
  end

  describe "feature flag gating", with_flag: { subtypes: false } do
    let(:owner) { create(:type, patterns: { subject: { blueprint: "X {{id}}", enabled: true } }) }

    before { type.link!(Type::ConfigurationLink::PATTERNS, source: owner) }

    it "ignores links and resolves to the type's own configuration" do
      expect(type.effective_source_for(Type::ConfigurationLink::PATTERNS)).to eq(type)
      expect(type.effective_patterns).to eq(type.patterns)
      expect(type).not_to be_replacement_pattern_defined_for(:subject)
    end
  end

  describe "#copy_configuration_from" do
    it "copies the source's subject patterns onto the type" do
      source = create(:type, patterns: { subject: { blueprint: "Copied {{id}}", enabled: true } })

      type.copy_configuration_from(source, Type::ConfigurationLink::PATTERNS)

      expect(type.reload.patterns.subject.blueprint).to eq("Copied {{id}}")
    end

    it "copies the source's PDF export config onto the type" do
      source = create(:type)
      source.pdf_export_templates.disable_all
      source.save!

      type.copy_configuration_from(source, Type::ConfigurationLink::PDF_EXPORT)

      expect(type.reload.export_templates_disabled).to eq(source.export_templates_disabled)
    end
  end
end
