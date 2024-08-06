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

module TableHelpers
  RSpec.describe Identifier do
    shared_examples "an identifier" do |name:, expected_identifier:|
      it "converts #{name.inspect} to identifier #{expected_identifier.inspect}" do
        expect(described_class.to_identifier(name)).to eq(expected_identifier)
      end
    end

    include_examples "an identifier", name: nil, expected_identifier: nil
    include_examples "an identifier", name: "Subject", expected_identifier: :subject
    include_examples "an identifier", name: "Work package", expected_identifier: :work_package
    include_examples "an identifier", name: "grand-child", expected_identifier: :grand_child
    include_examples "an identifier", name: "Child 1", expected_identifier: :child1
  end
end
