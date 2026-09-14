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
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe WorkPackage, "required custom fields" do
  shared_let(:status) { create(:status, is_default: true) }
  shared_let(:priority) { create(:priority, is_default: true) }
  shared_let(:author) { create(:user) }

  let(:custom_field) { create(:integer_wp_custom_field, is_for_all: true) }
  let(:type) { create(:type) }
  let(:project) { create(:project, types: [type], work_package_custom_fields: [custom_field]) }

  def show_the_field_on(variant, required:)
    variant.attribute_groups = [["Details", [custom_field.attribute_name]]]
    variant.custom_field_ids = [custom_field.id]
    variant.required_attributes = required ? [custom_field.attribute_name] : []
    variant.save!
    variant
  end

  def apply(variant, in_project: project)
    ProjectType.find_by(project: in_project, type:).update!(variant:)
    in_project.reload
  end

  def work_package(project_value: project, type_value: type)
    described_class.new(project: project_value, type: type_value, author:, status:, priority:,
                        subject: "S")
  end

  describe "#required_custom_field_ids" do
    it "is empty without a project, because no field is available then" do
      show_the_field_on(type.default_variant, required: true)

      expect(work_package(project_value: nil).required_custom_field_ids).to eq([])
    end

    it "is empty without a type, because no configuration applies then" do
      show_the_field_on(type.default_variant, required: true)

      expect(work_package(type_value: nil).required_custom_field_ids).to eq([])
    end

    it "is empty for a type whose base variant is missing" do
      stubbed = create(:type)
      stubbed.variants.destroy_all

      expect(work_package(type_value: stubbed.reload).required_custom_field_ids).to eq([])
    end

    it "reads the variant the project applies" do
      show_the_field_on(type.default_variant, required: true)

      expect(work_package.required_custom_field_ids).to contain_exactly(custom_field.id)
    end

    it "keys the cache per type, so two types in one request do not bleed" do
      other_type = create(:type)
      create(:project_type, project:, type: other_type)
      show_the_field_on(type.default_variant, required: true)
      show_the_field_on(other_type.default_variant, required: false)

      expect(work_package.required_custom_field_ids).to contain_exactly(custom_field.id)
      expect(work_package(type_value: other_type).required_custom_field_ids).to eq([])
    end
  end

  describe "#custom_field_required?" do
    it "is false when neither the field nor the variant demands a value" do
      show_the_field_on(type.default_variant, required: false)

      expect(work_package.custom_field_required?(custom_field)).to be(false)
    end

    it "is true when the variant demands a value" do
      show_the_field_on(type.default_variant, required: true)

      expect(work_package.custom_field_required?(custom_field)).to be(true)
    end

    it "is true when the field itself demands one everywhere, whatever the variant says" do
      custom_field.update!(is_required: true)
      show_the_field_on(type.default_variant, required: false)

      expect(work_package.custom_field_required?(custom_field)).to be(true)
    end
  end

  describe "the variant the project applies" do
    let(:named_variant) { create(:type_variant, type:) }

    before do
      show_the_field_on(type.default_variant, required: false)
      show_the_field_on(named_variant, required: true)
    end

    it "follows the applied variant rather than the type's base one" do
      apply(named_variant)

      expect(work_package.custom_field_required?(custom_field)).to be(true)
    end

    it "falls back to the base variant when the project applies none" do
      expect(work_package.custom_field_required?(custom_field)).to be(false)
    end

    it "answers per project for the same type" do
      apply(named_variant)
      lenient = create(:project, types: [type], work_package_custom_fields: [custom_field])

      expect(work_package.custom_field_required?(custom_field)).to be(true)
      expect(work_package(project_value: lenient).custom_field_required?(custom_field)).to be(false)
    end
  end

  # acts_as_customizable has its own validation context validate_on: :saving_custom_fields, so this is the context the
  # work package contracts validate in.
  describe "validating in the :saving_custom_fields context" do
    it "refuses a blank value the variant demands", :aggregate_failures do
      show_the_field_on(type.default_variant, required: true)

      subject = work_package
      expect(subject.valid?(:saving_custom_fields)).to be(false)
      expect(subject.errors[custom_field.attribute_name]).to include("can't be blank.")
    end

    it "accepts a blank value the variant leaves optional", :aggregate_failures do
      show_the_field_on(type.default_variant, required: false)

      subject = work_package
      expect(subject.valid?(:saving_custom_fields)).to be(true)
      expect(subject.errors[custom_field.attribute_name]).to be_empty
    end

    it "accepts the work package once the value is there" do
      show_the_field_on(type.default_variant, required: true)

      subject = work_package
      subject.custom_field_values = { custom_field.id => 5 }

      expect(subject.valid?(:saving_custom_fields)).to be(true)
    end

    it "ignores a demanded field the project has not activated", :aggregate_failures do
      show_the_field_on(type.default_variant, required: true)
      custom_field.update!(is_for_all: false)
      project.work_package_custom_fields = []

      subject = work_package
      expect(subject.available_custom_fields).to be_empty
      expect(subject.valid?(:saving_custom_fields)).to be(true)
    end
  end
end
