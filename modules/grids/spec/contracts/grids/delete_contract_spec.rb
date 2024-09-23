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

RSpec.describe Grids::DeleteContract do
  let(:user) { build_stubbed(:user) }
  let(:grid) do
    build_stubbed(:grid)
  end

  let(:instance) { described_class.new(grid, user) }

  before do
    allow(Grids::Configuration)
      .to receive(:writable?)
            .and_return(writable)

    allow(grid).to receive(:user_deletable?).and_return(user_deletable)
  end

  context "when writable" do
    let(:writable) { true }
    let(:user_deletable) { true }

    it "deletes the grid even if no valid widgets" do
      expect(instance.validate).to be_truthy
    end
  end

  context "when not writable" do
    let(:writable) { false }
    let(:user_deletable) { true }

    it "deletes the grid even if not valid" do
      expect(instance.validate).to be_falsey
    end
  end

  context "when not deletable" do
    let(:writable) { true }
    let(:user_deletable) { false }

    it "deletes the grid even if not valid" do
      expect(instance.validate).to be_falsey
    end
  end
end
