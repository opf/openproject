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

RSpec.describe OpenProject::Boards::GridRegistration do
  let(:project) { create(:project) }
  let(:permissions) { [:show_board_views] }
  let(:board) { create(:board_grid, project:) }
  let(:user) do
    create(:user,
           member_with_permissions: { project => permissions })
  end

  describe "from_scope" do
    subject { described_class.from_scope "/foobar/projects/bla/boards" }

    context "with a relative URL root", with_config: { rails_relative_url_root: "/foobar" } do
      it "maps that correctly" do
        expect(subject).to be_present
        expect(subject[:class]).to eq(Boards::Grid)
      end
    end
  end

  describe ".visible" do
    context "when having the view_boards permission" do
      it "returns the board" do
        expect(described_class.visible(user))
          .to match_array(board)
      end
    end

    context "when having the manage_board_views permission" do
      let(:permissions) { [:manage_board_views] }

      it "returns the board" do
        expect(described_class.visible(user))
          .to match_array(board)
      end
    end

    context "when having neither of the permissions" do
      let(:permissions) { [] }

      it "returns the board" do
        expect(described_class.visible(user))
          .to be_empty
      end
    end
  end
end
