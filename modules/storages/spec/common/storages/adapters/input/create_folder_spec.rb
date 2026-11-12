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

module Storages
  module Adapters
    module Input
      RSpec.describe CreateFolder do
        subject(:input) { described_class }

        describe ".new" do
          it "discourages direct instantiation" do
            expect { described_class.new(file_id: "file_id", parent_location: "/") }
              .to raise_error(NoMethodError, /private method 'new'/)
          end
        end

        describe ".build" do
          it "creates a success result for valid input data" do
            expect(input.build(parent_location: "/", folder_name: "DeathStar")).to be_success
          end

          it "coerces the parent folder into a ParentFolder object" do
            result = input.build(parent_location: "/", folder_name: "DeathStar").value!

            expect(result.parent_location).to be_a(Peripherals::ParentFolder)
          end

          it "creates a failure result for invalid input data" do
            expect(input.build(parent_location: "/", folder_name: 1)).to be_failure
            expect(input.build(parent_location: "/", folder_name: "")).to be_failure
            expect(input.build(parent_location: 1, folder_name: "DeathStar")).to be_failure
            expect(input.build(parent_location: "", folder_name: "DeathStar")).to be_failure
          end
        end
      end
    end
  end
end
