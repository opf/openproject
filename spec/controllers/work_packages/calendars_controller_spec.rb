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

describe WorkPackages::CalendarsController, type: :controller do
  let(:project) do
    FactoryBot.build_stubbed(:project).tap do |p|
      allow(Project)
        .to receive(:find)
        .with(p.id.to_s)
        .and_return(p)
    end
  end
  let(:permissions) { [:view_calendar] }
  let(:user) do
    FactoryBot.build_stubbed(:user).tap do |user|
      allow(user)
        .to receive(:allowed_to?) do |permission, p, global:|
        permission[:controller] == 'work_packages/calendars' &&
          permission[:action] == 'index' &&
          (p.nil? || p == project)
      end
    end
  end

  before { login_as(user) }

  describe '#index' do
    shared_examples_for 'calendar#index' do
      subject { response }

      it { is_expected.to be_successful }

      it { is_expected.to render_template('work_packages/calendars/index') }
    end

    context 'cross-project' do
      before do
        get :index
      end

      it_behaves_like 'calendar#index'
    end

    context 'project' do
      before do
        get :index, params: { project_id: project.id }
      end

      it_behaves_like 'calendar#index'
    end
  end
end
