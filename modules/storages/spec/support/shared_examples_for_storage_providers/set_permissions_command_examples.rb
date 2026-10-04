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

RSpec.shared_examples_for "adapter set_permissions_command: replaces already set permissions" do
  it "replaces fully the previously set permissions" do
    file_id = test_folder.id
    input_data = Storages::Adapters::Input::SetPermissions.build(file_id:, user_permissions: previous_permissions).value!
    result = described_class.call(storage:, auth_strategy:, input_data:)

    expect(result).to be_success
    expect(current_remote_permissions).to eq(previous_permissions)

    input_data = Storages::Adapters::Input::SetPermissions.build(file_id:, user_permissions: replacing_permissions).value!
    result = described_class.call(storage:, auth_strategy:, input_data:)

    expect(result).to be_success
    expect(current_remote_permissions).to eq(replacing_permissions)
  ensure
    clean_up file_id
  end
end

RSpec.shared_examples_for "adapter set_permissions_command: creates new permissions" do
  it "creates the new permissions" do
    file_id = test_folder.id

    expect(current_remote_permissions).to eq([])

    input_data = Storages::Adapters::Input::SetPermissions.build(file_id:, user_permissions:).value!
    result = described_class.call(storage:, auth_strategy:, input_data:)

    expect(result).to be_success
    expect(current_remote_permissions).to eq(user_permissions)
  ensure
    clean_up file_id
  end
end

RSpec.shared_examples_for "adapter set_permissions_command: unknown remote identity" do
  it "returns a failure" do
    file_id = test_folder.id
    input_data = Storages::Adapters::Input::SetPermissions.build(file_id:, user_permissions:).value!
    result = described_class.call(storage:, auth_strategy:, input_data:)

    expect(result).to be_failure

    error = result.failure
    expect(error.code).to eq(:unknown_remote_identity)
    expect(error.source).to eq(described_class)
  ensure
    clean_up file_id
  end
end
