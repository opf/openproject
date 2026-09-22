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
require Rails.root.join("db/migrate/20260922120000_convert_custom_field_activations_to_variants.rb")

RSpec.describe ConvertCustomFieldActivationsToVariants, type: :model do
  shared_let(:build_number) { create(:integer_wp_custom_field, name: "Build Number") }
  shared_let(:onboarding) { create(:string_wp_custom_field, name: "Onboarding activity") }
  shared_let(:everywhere) { create(:string_wp_custom_field, name: "Everywhere", is_for_all: true) }

  shared_let(:type) { create(:type, name: "Task", custom_fields: [build_number, onboarding, everywhere]) }

  let(:base_variant) { type.default_variant }

  def migrate
    ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }
  end

  def activate(custom_field, project)
    ActiveRecord::Base.connection.execute(<<~SQL.squish)
      INSERT INTO custom_fields_projects (custom_field_id, project_id)
      VALUES (#{custom_field.id}, #{project.id})
    SQL
  end

  def applied_variant(project)
    project.project_types.find_by!(type_id: type.id).variant
  end

  describe "a shape several projects share" do
    let!(:first) { create(:project, types: [type]) }
    let!(:second) { create(:project, types: [type]) }

    before do
      [first, second].each { activate(onboarding, it) }
      migrate
    end

    it "builds one global variant both projects apply" do
      variant = applied_variant(first)

      expect(variant).to eq applied_variant(second)
      expect(variant.project_id).to be_nil
      expect(type.variants.non_default_variants.count).to eq 1
    end

    it "names the variant after the fields it excludes" do
      expect(applied_variant(first).variant_name).to eq "Task without Build Number"
    end

    it "excludes only the field the projects had switched off" do
      expect(applied_variant(first).form_configuration_excluded_elements)
        .to contain_exactly("custom_field_#{build_number.id}")
    end

    it "leaves the field flagged for all projects alone" do
      expect(applied_variant(first).custom_fields).to include everywhere
    end
  end

  describe "a shape only one project has" do
    let!(:lonely) { create(:project, types: [type]) }
    let!(:other) { create(:project, types: [type]) }

    before do
      activate(onboarding, other)
      activate(everywhere, other)
      migrate
    end

    it "builds a variant that project owns" do
      expect(applied_variant(lonely).project).to eq lonely
    end

    it "names it after both excluded fields" do
      expect(applied_variant(lonely).variant_name)
        .to eq "Task without Build Number, Onboarding activity"
    end
  end

  describe "a project that switched nothing off" do
    let!(:untouched) { create(:project, types: [type]) }

    before do
      activate(build_number, untouched)
      activate(onboarding, untouched)
      migrate
    end

    it "keeps applying the base variant" do
      expect(applied_variant(untouched)).to eq base_variant
    end

    it "builds no variant at all" do
      expect(type.variants.non_default_variants).to be_empty
    end
  end

  describe "an archived project" do
    let!(:archived) { create(:project, types: [type], active: false) }

    before do
      activate(build_number, archived)
      migrate
    end

    it "is converted, so unarchiving restores the configuration it had" do
      expect(applied_variant(archived).form_configuration_excluded_elements)
        .to contain_exactly("custom_field_#{onboarding.id}")
    end
  end

  describe "a required field that was switched off" do
    let!(:project) { create(:project, types: [type]) }

    before do
      base_variant.update!(required_attributes: [onboarding.attribute_name])
      activate(build_number, project)
      migrate
    end

    it "is not required in that project" do
      expect(applied_variant(project).required_attributes).to be_empty
    end

    it "stays required for projects on the base variant" do
      expect(base_variant.required_attributes).to contain_exactly onboarding.attribute_name
    end
  end

  describe "naming when a type has many excluded fields" do
    shared_let(:wide_type) do
      fields = (1..8).map { create(:string_wp_custom_field, name: "Attribute number #{it}") }
      create(:type, name: "Feature", custom_fields: fields)
    end

    let!(:project) { create(:project, types: [wide_type]) }

    before { migrate }

    it "lists what fits the budget and summarises the rest" do
      variant = project.project_types.find_by!(type_id: wide_type.id).variant

      expect(variant.variant_name)
        .to eq "Feature without Attribute number 1, Attribute number 2, Attribute number 3 and 5 more fields"
      expect(variant.variant_name.length).to be <= described_class::NAME_BUDGET
    end
  end
end
