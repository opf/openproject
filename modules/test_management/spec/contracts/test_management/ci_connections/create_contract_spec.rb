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

RSpec.describe TestManagement::CiConnections::CreateContract do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_test_cases manage_test_ci] }) }

  it "builds the create and update contracts for a connection" do
    connection = TestManagement::CiConnection.new(project:, name: "Shop", provider: "github", repository: "my-org/shop")

    expect { described_class.new(connection, user) }.not_to raise_error
    expect { TestManagement::CiConnections::UpdateContract.new(connection, user) }.not_to raise_error
  end

  it "validates a form-like write with the remove flags" do
    connection = TestManagement::CiConnection.new(project:)
    connection.attributes = { name: "Shop", provider: "github", repository: "my-org/shop", token: "ghp_x",
                              remove_token: "0" }

    expect(described_class.new(connection, user).validate).to be(true)
  end

  it "builds every module contract with its own model" do
    contracts = Dir[OpenProject::TestManagement::Engine.root.join("app/contracts/test_management/**/*_contract.rb")].map do |path|
      path.delete_prefix("#{OpenProject::TestManagement::Engine.root.join('app/contracts')}/").delete_suffix(".rb").camelize.constantize
    end
    with_model = contracts.select do |klass|
      klass.respond_to?(:model) && klass.method(:model).source_location&.first.to_s.include?("test_management")
    end

    expect(with_model.size).to be >= 10
    with_model.each do |klass|
      expect { klass.new(klass.model.new, user) }.not_to raise_error, klass.name
    end
  end
end
