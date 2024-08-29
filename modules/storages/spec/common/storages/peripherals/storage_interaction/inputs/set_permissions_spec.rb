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

RSpec.describe Storages::Peripherals::StorageInteraction::Inputs::SetPermissions do
  describe ".new" do
    it "discourages direct instantiation" do
      expect { described_class.new(file_id: "file_id", user_permissions: []) }
        .to raise_error(NoMethodError, /private method `new'/)
    end
  end

  describe ".build" do
    it "creates a success result for valid input data" do
      expect(described_class.build(file_id: "1337", user_permissions: [])).to be_success
      expect(described_class.build(file_id: "1337",
                                   user_permissions: [{ user_id: "dart_vader", permissions: [] }])).to be_success
      expect(described_class.build(file_id: "1337",
                                   user_permissions: [{ user_id: "dart_vader",
                                                        permissions: [:read_files] }])).to be_success
    end

    it "creates a failure result for invalid input data" do
      expect(described_class.build(file_id: nil, user_permissions: [])).to be_failure
      expect(described_class.build(file_id: "", user_permissions: [])).to be_failure
      expect(described_class.build(file_id: "1337", user_permissions: {})).to be_failure

      expect(described_class.build(file_id: "1337", user_permissions: [:read_files])).to be_failure
      expect(described_class.build(file_id: "1337", user_permissions: [{ user: "rey", permissions: [] }])).to be_failure
      expect(described_class.build(file_id: "1337", user_permissions: [{ user_id: "rey" }])).to be_failure
      expect(described_class.build(file_id: "1337",
                                   user_permissions: [{ user_id: "rey", permissions: [:read] }])).to be_failure
      expect(described_class.build(file_id: "1337",
                                   user_permissions: [{ user_id: "rey", permissions: {} }])).to be_failure
    end
  end
end
