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

RSpec.describe WorkPackageTypes::FormConfiguration::LayoutLock, with_ee: %i[edit_attribute_groups] do
  shared_let(:user) { create(:admin) }
  let(:form) { create(:form_configuration) }
  let!(:details) { create(:form_configuration_group, form_configuration: form, label: "Details") }
  let!(:other) { create(:form_configuration_group, form_configuration: form, label: "Other") }
  let!(:priority) do
    create(:form_configuration_attribute, form_configuration: form, group: details, position: 1, attribute_key: "priority")
  end

  def rename_service(form_configuration)
    WorkPackageTypes::FormConfigurationGroups::UpdateService
      .new(user:, form_configuration:, group_key: "Details")
  end

  it "takes the form's layout lock" do
    allow(OpenProject::Mutex).to receive(:with_advisory_lock_transaction).and_call_original

    rename_service(form).call(name: "Specifics")

    expect(OpenProject::Mutex).to have_received(:with_advisory_lock_transaction).with(form, "layout")
  end

  it "reads the layout after locking, so a stale writer does not undo a committed move", :aggregate_failures do
    stale_form = FormConfiguration.find(form.id)
    stale_form.attribute_groups
    priority.place!(group: other, position: 1)

    call = rename_service(stale_form).call(name: "Specifics")

    expect(call).to be_success
    expect(other.members.reload.map(&:key)).to eq(%w[priority])
    expect(details.reload.label).to eq("Specifics")
  end

  it "rolls back what a failing writer already changed" do
    host = Class.new { include WorkPackageTypes::FormConfiguration::LayoutLock }.new

    result = host.send(:with_layout_lock, form) do
      details.update!(label: "Changed")
      ServiceResult.failure(message: "no")
    end

    expect(result).to be_failure
    expect(details.reload.label).to eq("Details")
  end

  {
    "creating a group" => lambda { |form, user|
      WorkPackageTypes::FormConfigurationGroups::CreateService
        .new(user:, form_configuration: form).call(group_type: "attribute", name: "New")
    },
    "deleting a group" => lambda { |form, user|
      WorkPackageTypes::FormConfigurationGroups::DeleteService
        .new(user:, form_configuration: form, group_key: "Other").call
    },
    "removing a row" => lambda { |form, user|
      WorkPackageTypes::FormConfigurationRows::DeleteService
        .new(user:, form_configuration: form, row_key: "priority").call
    }
  }.each do |description, writer|
    it "locks when #{description}" do
      allow(OpenProject::Mutex).to receive(:with_advisory_lock_transaction).and_call_original

      expect(writer.call(form, user)).to be_success

      expect(OpenProject::Mutex).to have_received(:with_advisory_lock_transaction).with(form, "layout")
    end
  end
end
