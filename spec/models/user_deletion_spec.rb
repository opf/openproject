#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe User, 'deletion', type: :model do
  let(:project) { FactoryBot.create(:project_with_types) }
  let(:user) { FactoryBot.create(:user, member_in_project: project) }
  let(:user2) { FactoryBot.create(:user) }
  let(:member) { project.members.first }
  let(:role) { member.roles.first }
  let(:status) { FactoryBot.create(:status) }

  let(:substitute_user) { DeletedUser.first }

  describe 'WHEN there is the user' do
    before do
      Principals::DeleteJob.perform_now(user)
    end

    it { expect(User.find_by(id: user.id)).to be_nil }
  end

  describe 'WHEN the user is a member of a project' do
    before do
      user
      member
    end

    it 'removes that member' do
      Principals::DeleteJob.perform_now(user)

      expect(Member.find_by(id: member.id)).to be_nil
      expect(Role.find_by(id: role.id)).to eq(role)
      expect(Project.find_by(id: project.id)).to eq(project)
    end
  end

  describe 'WHEN the user is watching something' do
    let(:watched) { FactoryBot.create(:work_package, project: project) }
    let(:watch) do
      Watcher.new(user: user,
                  watchable: watched)
    end

    before do
      watch.save!

      Principals::DeleteJob.perform_now(user)
    end

    it { expect(Watcher.find_by(id: watch.id)).to be_nil }
  end

  describe 'WHEN the user has a token created' do
    let(:token) do
      Token::RSS.new(user: user, value: 'loremipsum')
    end

    before do
      token.save!

      Principals::DeleteJob.perform_now(user)
    end

    it { expect(Token::RSS.find_by(id: token.id)).to be_nil }
  end

  describe 'WHEN the user has created a private query' do
    let(:query) { FactoryBot.build(:private_query, user: user) }

    before do
      query.save!

      Principals::DeleteJob.perform_now(user)
    end

    it { expect(Query.find_by(id: query.id)).to be_nil }
  end

  describe 'WHEN the user is assigned an issue category' do
    let(:category) do
      FactoryBot.build(:category, assigned_to: user,
                                  project: project)
    end

    before do
      category.save!
      Principals::DeleteJob.perform_now(user)
      category.reload
    end

    it { expect(Category.find_by(id: category.id)).to eq(category) }
    it { expect(category.assigned_to).to be_nil }
  end
end
