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
      RSpec.describe UploadLink do
        subject(:input) { described_class }

        describe ".new" do
          it "discourages direct instantiation" do
            expect { described_class.new(folder_id: "file_id", file_name: "name") }
              .to raise_error(NoMethodError, /private method 'new'/)
          end
        end

        describe ".build" do
          it "creates a success result for valid input data" do
            expect(input.build(folder_id: "ABDCE", file_name: "DeathStar")).to be_success
          end

          it "creates a failure result for invalid input data" do
            expect(input.build(folder_id: "/", file_name: 1)).to be_failure
            expect(input.build(folder_id: "/", file_name: "")).to be_failure
            expect(input.build(folder_id: 1, file_name: "DeathStar")).to be_failure
            expect(input.build(folder_id: "", file_name: "DeathStar")).to be_failure
          end
        end
      end
    end
  end
end
