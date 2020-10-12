#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Grids::Query, type: :model do
  include OpenProject::StaticRouting::UrlHelpers

  shared_let(:project) { FactoryBot.create(:project) }
  shared_let(:other_project) { FactoryBot.create(:project) }
  shared_let(:show_board_views_role) { FactoryBot.create(:role, permissions: [:show_board_views]) }
  shared_let(:other_role) { FactoryBot.create(:role, permissions: []) }
  shared_let(:current_user) do
    FactoryBot.create(:user).tap do |user|
      FactoryBot.create(:member, user: user, project: project, roles: [show_board_views_role])
      FactoryBot.create(:member, user: user, project: other_project, roles: [other_role])
    end
  end
  let!(:board_grid) do
    FactoryBot.create(:board_grid, project: project)
  end
  let!(:other_board_grid) do
    FactoryBot.create(:board_grid, project: other_project)
  end
  let(:instance) { described_class.new }

  before do
    login_as(current_user)
  end

  context 'without a filter' do
    describe '#results' do
      it 'is the same as getting all the boards visible to the user' do
        expect(instance.results).to match_array [board_grid]
      end
    end
  end

  context 'with a scope filter' do
    context 'filtering for a projects/:project_id/boards' do
      before do
        instance.where('scope', '=', [project_work_package_boards_path(project)])
      end

      describe '#results' do
        it 'yields boards assigned to the project' do
          expect(instance.results).to match_array [board_grid]
        end
      end

      describe '#valid?' do
        it 'is true' do
          expect(instance).to be_valid
        end
      end
    end
  end
end
