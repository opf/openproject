#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

describe 'work_packages/show', type: :view do
  let(:work_package) { FactoryGirl.create(:work_package, description: '') }
  let(:attachment)   {
    FactoryGirl.create(:attached_picture,
                       author: work_package.author,
                       container: work_package,
                       filename: 'foo.jpg')
  }

  it 'renders correct image paths in journal entries' do
    work_package.add_journal(work_package.author, 'bar !foo.jpg! bar')
    work_package.attachments << attachment
    work_package.save
    render 'history', work_package: work_package, journals: work_package.journals
    expect(rendered)
      .to have_selector "img[src='/attachments/#{attachment.id}/download']"
  end

  context 'watchers list is sorted alphabeticaly' do
    let!(:project) { FactoryGirl.create(:project) }
    let!(:work_package_watchers) { FactoryGirl.create(:work_package, project: project) }
    let!(:role) { FactoryGirl.create(:role, permissions: [:view_work_packages]) }

    let!(:watching_user_1) do
      FactoryGirl.create(:user, member_in_project: project, member_through_role: role, firstname: 'Odyssey').tap { |user| Watcher.create(watchable: work_package_watchers, user: user) }
    end

    let!(:watching_user_2) do
      FactoryGirl.create(:user, member_in_project: project, member_through_role: role, firstname: 'Feodor').tap { |user| Watcher.create(watchable: work_package_watchers, user: user) }
    end
    let!(:watching_user_3) do
      FactoryGirl.create(:user, member_in_project: project, member_through_role: role, firstname: 'Mahboobeh').tap { |user| Watcher.create(watchable: work_package_watchers, user: user) }
    end
    let!(:watching_user_4) do
      FactoryGirl.create(:user, member_in_project: project, member_through_role: role, firstname: 'Daenerys').tap { |user| Watcher.create(watchable: work_package_watchers, user: user) }
    end
    let!(:watching_user_5) do
      FactoryGirl.create(:user, member_in_project: project, member_through_role: role, firstname: 'Ned').tap { |user| Watcher.create(watchable: work_package_watchers, user: user) }
    end

    before do
      render 'watchers/watchers', watched: work_package_watchers
    end

    it {
      expect(rendered).to have_xpath('//ul/li[1]/a', text: watching_user_4.name)
      expect(rendered).to have_xpath('//ul/li[2]/a', text: watching_user_2.name)
      expect(rendered).to have_xpath('//ul/li[3]/a', text: watching_user_3.name)
      expect(rendered).to have_xpath('//ul/li[4]/a', text: watching_user_5.name)
      expect(rendered).to have_xpath('//ul/li[5]/a', text: watching_user_1.name)
    }
  end
end
