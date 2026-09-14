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
require "support/edit_fields/edit_field"
require "features/page_objects/notification"

RSpec.describe "creating a work package with a per-type required custom field", :js do
  shared_let(:status) { create(:status, is_default: true) }
  shared_let(:priority) { create(:priority, is_default: true) }

  shared_let(:custom_field) do
    create(:work_package_custom_field, field_format: "string", name: "Impact", is_for_all: true)
  end

  shared_let(:demanding_type) { create(:type_task) }
  shared_let(:permissive_type) { create(:type_bug, position: demanding_type.position + 1) }

  shared_let(:project) do
    create(:project, types: [demanding_type, permissive_type], work_package_custom_fields: [custom_field])
  end

  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_work_packages add_work_packages edit_work_packages] })
  end

  let(:wp_page) { Pages::FullWorkPackageCreate.new }
  let(:subject_field) { wp_page.edit_field :subject }
  let(:type_field) { wp_page.edit_field :type }
  let(:toaster) { PageObjects::Notifications.new(page) }

  def show_field_on(variant, required:)
    variant.attribute_groups = [["Details", [custom_field.attribute_name]]]
    variant.custom_field_ids = [custom_field.id]
    variant.required_attributes = required ? [custom_field.attribute_name] : []
    variant.save!
  end

  before do
    show_field_on(demanding_type.default_variant, required: true)
    show_field_on(permissive_type.default_variant, required: false)

    login_as user
    visit new_project_work_packages_path(project)
  end

  def create_as(type)
    type_field.activate!
    type_field.set_value type.name
    wait_for_network_idle

    subject_field.update("A new work package", save: true)
  end

  it "refuses to save the type that demands the field and accepts the one that does not" do
    create_as(demanding_type)

    toaster.expect_error("#{custom_field.name} can't be blank.")
    expect(WorkPackage.count).to eq(0)

    wp_page.dismiss_toaster!

    field = wp_page.edit_field custom_field.attribute_name(:camel_case)
    field.update("Severe", save: true)

    wp_page.expect_and_dismiss_toaster(message: "Successful creation.")
    expect(WorkPackage.last.typed_custom_value_for(custom_field)).to eq("Severe")
  end

  it "saves the permissive type with the field left empty" do
    create_as(permissive_type)

    wp_page.expect_and_dismiss_toaster(message: "Successful creation.")

    work_package = WorkPackage.last
    expect(work_package.type).to eq(permissive_type)
    expect(work_package.typed_custom_value_for(custom_field)).to be_nil
  end
end
