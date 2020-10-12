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

describe User, 'deletion', type: :model do
  let(:project) { FactoryBot.create(:project_with_types) }
  let(:user) { FactoryBot.create(:user, member_in_project: project) }
  let(:user2) { FactoryBot.create(:user) }
  let(:member) { project.members.first }
  let(:role) { member.roles.first }
  let(:status) { FactoryBot.create(:status) }
  let(:issue) {
    FactoryBot.create(:work_package, type: project.types.first,
                                      author: user,
                                      project: project,
                                      status: status,
                                      assigned_to: user)
  }
  let(:issue2) {
    FactoryBot.create(:work_package, type: project.types.first,
                                      author: user2,
                                      project: project,
                                      status: status,
                                      assigned_to: user2)
  }

  let(:substitute_user) { DeletedUser.first }

  describe 'WHEN there is the user' do
    before do
      user.destroy
    end

    it { expect(User.find_by(id: user.id)).to be_nil }
  end

  shared_examples_for 'updated journalized associated object' do
    before do
      allow(User).to receive(:current).and_return user2
      associations.each do |association|
        associated_instance.send(association.to_s + '=', user2)
      end
      associated_instance.save!

      allow(User).to receive(:current).and_return user # in order to have the content journal created by the user
      associated_instance.reload
      associations.each do |association|
        associated_instance.send(association.to_s + '=', user)
      end
      associated_instance.save!

      user.destroy
      associated_instance.reload
    end

    it { expect(associated_class.find_by(id: associated_instance.id)).to eq(associated_instance) }
    it 'should replace the user on all associations' do
      associations.each do |association|
        expect(associated_instance.send(association)).to eq(substitute_user)
      end
    end
    it { expect(associated_instance.journals.first.user).to eq(user2) }
    it 'should update first journal changes' do
      associations.each do |association|
        expect(associated_instance.journals.first.details[association_key association].last).to eq(user2.id)
      end
    end
    it { expect(associated_instance.journals.last.user).to eq(substitute_user) }
    it 'should update second journal changes' do
      associations.each do |association|
        expect(associated_instance.journals.last.details[association_key association].last).to eq(substitute_user.id)
      end
    end
  end

  def association_key(association)
    "#{association}_id".parameterize.underscore.to_sym
  end

  shared_examples_for 'created associated object' do
    before do
      associations.each do |association|
        associated_instance.send(association.to_s + '=', user)
      end
      associated_instance.save!

      user.destroy
      associated_instance.reload
    end

    it { expect(associated_class.find_by(id: associated_instance.id)).to eq(associated_instance) }
    it 'should replace the user on all associations' do
      associations.each do |association|
        expect(associated_instance.send(association)).to eq(substitute_user)
      end
    end
  end

  shared_examples_for 'created journalized associated object' do
    before do
      allow(User).to receive(:current).and_return user # in order to have the content journal created by the user
      associations.each do |association|
        associated_instance.send(association.to_s + '=', user)
      end
      associated_instance.save!

      allow(User).to receive(:current).and_return user2
      associated_instance.reload
      associations.each do |association|
        associated_instance.send(association.to_s + '=', user2)
      end
      associated_instance.save!

      user.destroy
      associated_instance.reload
    end

    it { expect(associated_class.find_by(id: associated_instance.id)).to eq(associated_instance) }
    it 'should keep the current user on all associations' do
      associations.each do |association|
        expect(associated_instance.send(association)).to eq(user2)
      end
    end
    it { expect(associated_instance.journals.first.user).to eq(substitute_user) }
    it 'should update the first journal' do
      associations.each do |association|
        expect(associated_instance.journals.first.details[association_key association].last).to eq(substitute_user.id)
      end
    end
    it { expect(associated_instance.journals.last.user).to eq(user2) }
    it 'should update the last journal' do
      associations.each do |association|
        expect(associated_instance.journals.last.details[association_key association].first).to eq(substitute_user.id)
        expect(associated_instance.journals.last.details[association_key association].last).to eq(user2.id)
      end
    end
  end

  describe 'WHEN the user has created one attachment' do
    let(:associated_instance) { FactoryBot.build(:attachment) }
    let(:associated_class) { Attachment }
    let(:associations) { [:author] }

    it_should_behave_like 'created journalized associated object'
  end

  describe 'WHEN the user has updated one attachment' do
    let(:associated_instance) { FactoryBot.build(:attachment) }
    let(:associated_class) { Attachment }
    let(:associations) { [:author] }

    it_should_behave_like 'updated journalized associated object'
  end

  describe 'WHEN the user has an issue created and assigned' do
    let(:associated_instance) {
      FactoryBot.build(:work_package, type: project.types.first,
                                       project: project,
                                       status: status)
    }
    let(:associated_class) { WorkPackage }
    let(:associations) { [:author, :assigned_to, :responsible] }

    it_should_behave_like 'created journalized associated object'
  end

  describe 'WHEN the user has an issue updated and assigned' do
    let(:associated_instance) {
      FactoryBot.build(:work_package, type: project.types.first,
                                       project: project,
                                       status: status)
    }
    let(:associated_class) { WorkPackage }
    let(:associations) { [:author, :assigned_to, :responsible] }

    before do
      allow(User).to receive(:current).and_return user2
      associated_instance.author = user2
      associated_instance.assigned_to = user2
      associated_instance.responsible = user2
      associated_instance.save!

      allow(User).to receive(:current).and_return user # in order to have the content journal created by the user
      associated_instance.reload
      associated_instance.author = user
      associated_instance.assigned_to = user
      associated_instance.responsible = user
      associated_instance.save!

      user.destroy
      associated_instance.reload
    end

    it { expect(associated_class.find_by(id: associated_instance.id)).to eq(associated_instance) }
    it 'should replace the user on all associations' do
      expect(associated_instance.author).to eq(substitute_user)
      expect(associated_instance.assigned_to).to be_nil
      expect(associated_instance.responsible).to be_nil
    end
    it { expect(associated_instance.journals.first.user).to eq(user2) }
    it 'should update first journal changes' do
      associations.each do |association|
        expect(associated_instance.journals.first.details[association_key association].last).to eq(user2.id)
      end
    end
    it { expect(associated_instance.journals.last.user).to eq(substitute_user) }
    it 'should update second journal changes' do
      associations.each do |association|
        expect(associated_instance.journals.last.details[association_key association].last).to eq(substitute_user.id)
      end
    end
  end

  describe 'WHEN the user has updated a wiki content' do
    let(:associated_instance) { FactoryBot.build(:wiki_content) }
    let(:associated_class) { WikiContent }
    let(:associations) { [:author] }

    it_should_behave_like 'updated journalized associated object'
  end

  describe 'WHEN the user has created a wiki content' do
    let(:associated_instance) { FactoryBot.build(:wiki_content) }
    let(:associated_class) { WikiContent }
    let(:associations) { [:author] }

    it_should_behave_like 'created journalized associated object'
  end

  describe 'WHEN the user has created a news' do
    let(:associated_instance) { FactoryBot.build(:news) }
    let(:associated_class) { News }
    let(:associations) { [:author] }

    it_should_behave_like 'created journalized associated object'
  end

  describe 'WHEN the user has worked on news' do
    let(:associated_instance) { FactoryBot.build(:news) }
    let(:associated_class) { News }
    let(:associations) { [:author] }

    it_should_behave_like 'updated journalized associated object'
  end

  describe 'WHEN the user has created a message' do
    let(:associated_instance) { FactoryBot.build(:message) }
    let(:associated_class) { Message }
    let(:associations) { [:author] }

    it_should_behave_like 'created journalized associated object'
  end

  describe 'WHEN the user has worked on message' do
    let(:associated_instance) { FactoryBot.build(:message) }
    let(:associated_class) { Message }
    let(:associations) { [:author] }

    it_should_behave_like 'updated journalized associated object'
  end

  describe 'WHEN the user has created a time entry' do
    let(:associated_instance) {
      FactoryBot.build(:time_entry, project: project,
                                     work_package: issue,
                                     hours: 2,
                                     activity: FactoryBot.create(:time_entry_activity))
    }
    let(:associated_class) { TimeEntry }
    let(:associations) { [:user] }

    it_should_behave_like 'created journalized associated object'
  end

  describe 'WHEN the user has worked on time_entry' do
    let(:associated_instance) {
      FactoryBot.build(:time_entry, project: project,
                                     work_package: issue,
                                     hours: 2,
                                     activity: FactoryBot.create(:time_entry_activity))
    }
    let(:associated_class) { TimeEntry }
    let(:associations) { [:user] }

    it_should_behave_like 'updated journalized associated object'
  end

  describe 'WHEN the user has commented' do
    let(:news) { FactoryBot.create(:news, author: user) }

    let(:associated_instance) {
      Comment.new(commented: news,
                  comments: 'lorem')
    }

    let(:associated_class) { Comment }
    let(:associations) { [:author] }

    it_should_behave_like 'created associated object'
  end

  describe 'WHEN the user is a member of a project' do
    before do
      user
      member
    end

    it 'removes that member' do
      user.destroy

      expect(Member.find_by(id: member.id)).to be_nil
      expect(Role.find_by(id: role.id)).to eq(role)
      expect(Project.find_by(id: project.id)).to eq(project)
    end
  end

  describe 'WHEN the user is watching something' do
    let(:watched) { FactoryBot.create(:work_package, project: project) }
    let(:watch) {
      Watcher.new(user: user,
                  watchable: watched)
    }

    before do
      watch.save!

      user.destroy
    end

    it { expect(Watcher.find_by(id: watch.id)).to be_nil }
  end

  describe 'WHEN the user has a token created' do
    let(:token) {
      Token::RSS.new(user: user, value: 'loremipsum')
    }

    before do
      token.save!

      user.destroy
    end

    it { expect(Token::RSS.find_by(id: token.id)).to be_nil }
  end

  describe 'WHEN the user has created a private query' do
    let(:query) { FactoryBot.build(:private_query, user: user) }

    before do
      query.save!

      user.destroy
    end

    it { expect(Query.find_by(id: query.id)).to be_nil }
  end

  describe 'WHEN the user has created a public query' do
    let(:associated_instance) { FactoryBot.build(:public_query) }

    let(:associated_class) { Query }
    let(:associations) { [:user] }

    it_should_behave_like 'created associated object'
  end

  describe 'WHEN the user has created a changeset' do
    with_virtual_subversion_repository do
      let(:associated_instance) do
        FactoryBot.build(:changeset,
                          repository_id: repository.id,
                          committer: user.login)
      end

      let(:associated_class) { Changeset }
      let(:associations) { [:user] }
    end

    it_should_behave_like 'created journalized associated object'
  end

  describe 'WHEN the user has updated a changeset' do
    with_virtual_subversion_repository do
      let(:associated_instance) do
        FactoryBot.build(:changeset,
                          repository_id: repository.id,
                          committer: user2.login)
      end
    end

    let(:associated_class) { Changeset }
    let(:associations) { [:user] }

    before do
      allow(User).to receive(:current).and_return user2
      associated_instance.user = user2
      associated_instance.save!

      allow(User).to receive(:current).and_return user # in order to have the content journal created by the user
      associated_instance.reload
      associated_instance.user = user
      associated_instance.save!

      user.destroy
      associated_instance.reload
    end

    it { expect(associated_class.find_by(id: associated_instance.id)).to eq(associated_instance) }
    it 'should replace the user on all associations' do
      expect(associated_instance.user).to be_nil
    end
    it { expect(associated_instance.journals.first.user).to eq(user2) }
    it 'should update first journal changes' do
      expect(associated_instance.journals.first.details[:user_id].last).to eq(user2.id)
    end
    it { expect(associated_instance.journals.last.user).to eq(substitute_user) }
    it 'should update second journal changes' do
      expect(associated_instance.journals.last.details[:user_id].last).to eq(substitute_user.id)
    end
  end

  describe 'WHEN the user is assigned an issue category' do
    let(:category) {
      FactoryBot.build(:category, assigned_to: user,
                                   project: project)
    }

    before do
      category.save!
      user.destroy
      category.reload
    end

    it { expect(Category.find_by(id: category.id)).to eq(category) }
    it { expect(category.assigned_to).to be_nil }
  end
end
