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

RSpec.describe FormConfiguration do
  shared_let(:admin) { create(:admin) }

  describe "naming" do
    it "names a form after what started it" do
      expect(described_class.implicit_name("Bug")).to eq("Bug form")
    end

    it "steps past a name already taken, whatever the casing" do
      create(:form_configuration, name: "Bug form")

      expect(described_class.implicit_name("bug")).to eq("bug form (2)")
    end

    it "refuses a second form with the same name" do
      create(:form_configuration, name: "Bug form")

      expect(build(:form_configuration, name: "BUG FORM")).not_to be_valid
    end

    it "is the form a new type starts with" do
      expect(create(:type, name: "Bug").default_variant.form_configuration.name).to eq("Bug form")
    end
  end

  describe "its own groups" do
    let(:milestone) { create(:type_milestone) }
    let(:form) { milestone.default_variant.form_configuration }

    it "starts on the defaults of a type that is not a milestone" do
      expect(form.attribute_groups.map(&:key)).to include(:estimates_and_progress)
      expect(milestone.default_variant.attribute_groups.map(&:key)).not_to include(:estimates_and_progress)
    end

    it "does not count what it reads its defaults through among its variants" do
      form.attribute_groups

      expect(form.type_variants).to contain_exactly(milestone.default_variant)
    end

    it "stores groups every variant using it reads" do
      form.attribute_groups = [["Planning", %w[assignee]]]
      form.save!

      expect(milestone.default_variant.reload.attribute_groups.map(&:key)).to eq(["Planning"])
    end
  end

  describe "stable rows" do
    let(:form) { create(:form_configuration) }

    before do
      form.update!(attribute_groups: [["Planning", %w[assignee date]], [:details, %w[priority]]])
      form.reload
    end

    def row_of(key) = form.form_attributes.find { it.key == key }

    it "keeps a group's row when the group is renamed" do
      planning = form.form_groups.find_by(label: "Planning")
      groups = form.attribute_groups
      groups.first.key = "Scheduling"

      form.update!(attribute_groups: groups)

      expect(form.reload.form_groups.find_by(label: "Scheduling").id).to eq(planning.id)
    end

    it "keeps an attribute's row when it moves to another group" do
      assignee = row_of("assignee")

      form.update!(attribute_groups: [["Planning", %w[date]], [:details, %w[priority assignee]]])

      expect(form.reload.form_groups.find_by(default_key: "details").members.map(&:id)).to include(assignee.id)
    end

    it "keeps the row of an attribute taken off the form, as inactive" do
      date = row_of("date")

      form.update!(attribute_groups: [["Planning", %w[assignee]], [:details, %w[priority]]])

      expect(FormConfigurationAttribute.find(date.id)).not_to be_active
    end
  end

  describe "deletion" do
    it "is refused while a variant still references it" do
      form = create(:type).default_variant.form_configuration

      expect(form.destroy).to be_falsey
      expect(form.errors).to be_of_kind(:base, :"restrict_dependent_destroy.has_many")
    end

    it "is refused for the default form, and keeps its groups" do
      form = create(:form_configuration, is_default: true)
      form.update!(attribute_groups: [["Details", %w[assignee]]])

      expect(form.destroy).to be_falsey
      expect(form.errors).to be_of_kind(:base, :default_undeletable)
      expect(form.reload.form_groups).to be_present
    end
  end

  describe "the default form" do
    it "is the one form marked as default" do
      create(:form_configuration)
      default = create(:form_configuration, is_default: true)

      expect(described_class.default_form).to eq(default)
    end

    it "moves to the form marked last" do
      previous = create(:form_configuration, is_default: true)
      form = create(:form_configuration)

      form.update!(is_default: true)

      expect(previous.reload).not_to be_is_default
      expect(described_class.default_form).to eq(form)
    end

    it "comes first in the display order, the others by name" do
      create(:form_configuration, name: "beta")
      create(:form_configuration, name: "Alpha")
      create(:form_configuration, name: "Zulu", is_default: true)

      expect(described_class.in_display_order.pluck(:name)).to eq(%w[Zulu Alpha beta])
    end

    it "does not exist until one is marked" do
      create(:form_configuration)

      expect(described_class.default_form).to be_nil
    end
  end

  describe "embedded queries" do
    let(:variant) { create(:type).default_variant }
    let(:query) { build(:global_query, user_id: 0) }

    before do
      login_as(admin)
      variant.attribute_groups = [["Related", [query]]]
      variant.save!
    end

    it "destroys a query once its group leaves the form" do
      variant.attribute_groups = [["details", %w[assignee]]]
      variant.save!

      expect(Query.find_by(id: query.id)).to be_nil
    end

    it "destroys its queries with the form" do
      form = variant.form_configuration
      variant.destroy

      form.reload.destroy

      expect(Query.find_by(id: query.id)).to be_nil
    end
  end

  describe "#reload" do
    it "drops the memoized attribute group objects" do
      form = create(:form_configuration)
      group = create(:form_configuration_group, form_configuration: form, label: "Details")
      expect(form.attribute_groups.map(&:key)).to eq(["Details"])

      group.update!(label: "Specifics")

      expect(form.reload.attribute_groups.map(&:key)).to eq(["Specifics"])
    end
  end
end
