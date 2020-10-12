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

describe Overviews::OverviewsController, type: :controller do
  
  let(:permissions) do
    %i(view_project)
  end
  let(:current_user) do
    FactoryBot.build_stubbed(:user).tap do |u|
      allow(u)
        .to receive(:allowed_to?) do |permission, permission_project, _global|
        permission_project == project &&
          (permissions.include?(permission) ||
          [{ controller: 'overviews/overviews', action: 'show' },
           { controller: '/news', action: 'index' }].include?(permission))
      end
    end
  end
  let(:project) do
    FactoryBot.build_stubbed(:project).tap do |p|
      allow(Project)
        .to receive(:find)
        .with(p.id.to_s)
        .and_return(p)
    end
  end

  let(:main_app_routes) do
    Rails.application.routes.url_helpers
  end

  before do
    login_as current_user
  end

  describe '#show' do
    context 'with jump parameter' do
      it 'redirects to active tab' do
        get :show, params: { project_id: project.id, jump: 'news' }

        expect(response)
          .to redirect_to main_app_routes.project_news_index_path(project)
      end

      it 'ignores inactive/unpermitted module' do
        get :show, params: { project_id: project.id, jump: 'work_packages' }

        expect(response)
          .to be_successful
      end

      it 'ignores bogus module' do
        get :show, params: { project_id: project.id, jump: 'foobar' }

        expect(response)
          .to be_successful
      end
    end
  end
end
