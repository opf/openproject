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

describe 'Journalized Objects' do
  before(:each) do
    @type ||= FactoryGirl.create(:type_feature)
    @project ||= FactoryGirl.create(:project_with_types)
    @current = FactoryGirl.create(:user, login: 'user1', mail: 'user1@users.com')
    allow(User).to receive(:current).and_return(@current)
  end

  it 'should work with work packages' do
    @status_open ||= FactoryGirl.create(:status, name: 'Open', is_default: true)
    @work_package ||= FactoryGirl.create(:work_package, project: @project, status: @status_open, type: @type, author: @current)

    initial_journal = @work_package.journals.first
    recreated_journal = @work_package.recreate_initial_journal!

    expect(initial_journal).to be_identical(recreated_journal)
  end

  it 'should work with news' do
    @news ||= FactoryGirl.create(:news, project: @project, author: @current, title: 'Test', summary: 'Test', description: 'Test')

    initial_journal = @news.journals.first
    recreated_journal = @news.recreate_initial_journal!

    expect(initial_journal).to be_identical(recreated_journal)
  end

  it 'should work with wiki content' do
    @wiki_content ||= FactoryGirl.create(:wiki_content, author: @current)

    initial_journal = @wiki_content.journals.first
    recreated_journal = @wiki_content.recreate_initial_journal!

    expect(initial_journal).to be_identical(recreated_journal)
  end

  it 'should work with messages' do
    @message ||= FactoryGirl.create(:message, content: 'Test', subject: 'Test', author: @current)

    initial_journal = @message.journals.first
    recreated_journal = @message.recreate_initial_journal!

    expect(initial_journal).to be_identical(recreated_journal)
  end

  it 'should work with time entries' do
    @status_open ||= FactoryGirl.create(:status, name: 'Open', is_default: true)
    @work_package ||= FactoryGirl.create(:work_package, project: @project, status: @status_open, type: @type, author: @current)

    @time_entry ||= FactoryGirl.create(:time_entry, work_package: @work_package, project: @project, spent_on: Time.now, hours: 5, user: @current, activity: FactoryGirl.create(:time_entry_activity))

    initial_journal = @time_entry.journals.first
    recreated_journal = @time_entry.recreate_initial_journal!

    expect(initial_journal).to be_identical(recreated_journal)
  end

  it 'should work with attachments' do
    @attachment ||= FactoryGirl.create(:attachment, container: FactoryGirl.create(:work_package), author: @current)

    initial_journal = @attachment.journals.first
    recreated_journal = @attachment.recreate_initial_journal!

    expect(initial_journal).to be_identical(recreated_journal)
  end

  it 'should work with changesets' do
    Setting.enabled_scm = ['Subversion']
    @repository ||= Repository.factory('Subversion', url: 'http://svn.test.com')
    @repository.save!
    @changeset ||= FactoryGirl.create(:changeset, committer: @current.login, repository: @repository)

    initial_journal = @changeset.journals.first
    recreated_journal = @changeset.recreate_initial_journal!

    expect(initial_journal).to be_identical(recreated_journal)
  end

  describe 'journal_editable_by?' do
    context 'when the journable is a work package' do
      let!(:user) { FactoryGirl.create(:user) }
      let!(:project) { FactoryGirl.create(:project_with_types) }
      let!(:role) { FactoryGirl.create(:role, permissions: [:edit_work_packages]) }
      let!(:member) {
        FactoryGirl.create(:member, project: project,
                                    roles: [role],
                                    principal: user)
      }
      let!(:work_package) {
        FactoryGirl.build(:work_package, type: project.types.first,
                                         author: user,
                                         project: project,
                                         description: '')
      }

      subject { work_package.journal_editable_by?(user) }

      context 'and the user has no permission to "edit_work_packages"' do
        before do
          role.remove_permission! :edit_work_packages
        end

        it { is_expected.to be_falsey }
      end
    end
  end

end
