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

RSpec.describe "Models acting as list (acts_as_list)" do # rubocop:disable RSpec/DescribeClass
  it "includes the patch" do
    expect(ActiveRecord::Acts::List::InstanceMethods.included_modules).to include(OpenProject::Patches::ActsAsList)
  end

  describe "#move_to=" do
    let(:includer) do
      clazz = Class.new do
        include OpenProject::Patches::ActsAsList

        def move_to_top; end

        def move_to_bottom; end

        def move_higher; end

        def move_lower; end
      end

      clazz.new
    end

    before do
      allow(includer).to receive(:move_to_top)
      allow(includer).to receive(:move_to_bottom)
      allow(includer).to receive(:move_higher)
      allow(includer).to receive(:move_lower)
    end

    it "moves to top when wanting to move highest" do
      includer.move_to = "highest"

      without_partial_double_verification do
        expect(includer).to have_received :move_to_top
      end
    end

    it "moves to bottom when wanting to move lowest" do
      includer.move_to = "lowest"

      without_partial_double_verification do
        expect(includer).to have_received :move_to_bottom
      end
    end

    it "moves higher when wanting to move higher" do
      includer.move_to = "higher"

      without_partial_double_verification do
        expect(includer).to have_received :move_higher
      end
    end

    it "moves lower when wanting to move lower" do
      includer.move_to = "lower"

      without_partial_double_verification do
        expect(includer).to have_received :move_lower
      end
    end
  end
end
