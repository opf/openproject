#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe OpenProject::Acts::Watchable do
  let(:project) { FactoryGirl.build(:project) }
  let(:work_package) { FactoryGirl.build(:work_package, project: project) }
  let(:users) { FactoryGirl.build_list(:user, 3) }

  before do
    allow(project).to receive(:users).and_return(users)
  end

  describe '#possible_watcher_users' do
    subject { work_package.possible_watcher_users }

    context 'supports #visible?' do
      context 'all are visible' do
        before { allow(work_package).to receive(:visible?).and_return(true) }

        it { is_expected.to match_array(users) }
      end

      context 'all are invisible' do
        before { allow(work_package).to receive(:visible?).and_return(false) }

        it { is_expected.to be_empty }
      end
    end

    context 'does not support #visible?' do
      before { allow(work_package).to receive(:respond_to?).with(:visible?).and_return(false) }

      it { is_expected.to match_array(users) }
    end
  end
end
