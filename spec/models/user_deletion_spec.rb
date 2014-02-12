#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

describe User, 'deletion' do
  let(:project) { FactoryGirl.create(:project_with_types) }
  let(:user) { FactoryGirl.build(:user, :member_in_project => project) }
  let(:user2) { FactoryGirl.build(:user) }
  let(:member) { project.members.first }
  let(:role) { member.roles.first }
  let(:status) { FactoryGirl.create(:status) }
  let(:issue) { FactoryGirl.create(:work_package, :type => project.types.first,
                                                  :author => user,
                                                  :project => project,
                                                  :status => status,
                                                  :assigned_to => user) }
  let(:issue2) { FactoryGirl.create(:work_package, :type => project.types.first,
                                                   :author => user2,
                                                   :project => project,
                                                   :status => status,
                                                   :assigned_to => user2) }

  let(:substitute_user) { DeletedUser.first }

  before do
    # for some reason there seem to be users in the db
    User.delete_all
    user.save!
    user2.save!
  end

  describe "WHEN there is the user" do
    before do
      user.destroy
    end

    it { User.find_by_id(user.id).should be_nil }
  end

  shared_examples_for "updated journalized associated object" do
    before do
      User.stub(:current).and_return user2
      associations.each do |association|
        associated_instance.send(association.to_s + "=", user2)
      end
      associated_instance.save!

      User.stub(:current).and_return user # in order to have the content journal created by the user
      associated_instance.reload
      associations.each do |association|
        associated_instance.send(association.to_s + "=", user)
      end
      associated_instance.save!

      user.destroy
      associated_instance.reload
    end

    it { associated_class.find_by_id(associated_instance.id).should == associated_instance }
    it "should replace the user on all associations" do
      associations.each do |association|
        associated_instance.send(association).should == substitute_user
      end
    end
    it { associated_instance.journals.first.user.should == user2 }
    it "should update first journal changes" do
      associations.each do |association|
        associated_instance.journals.first.changed_data[association_key association].last.should == user2.id
      end
    end
    it { associated_instance.journals.last.user.should == substitute_user }
    it "should update second journal changes" do
      associations.each do |association|
        associated_instance.journals.last.changed_data[association_key association].last.should == substitute_user.id
      end
    end
  end

  def association_key(association)
    "#{association.to_s}_id".parameterize.underscore.to_sym
  end

  shared_examples_for "created associated object" do
    before do
      associations.each do |association|
        associated_instance.send(association.to_s + "=", user)
      end
      associated_instance.save!

      user.destroy
      associated_instance.reload
    end

    it { associated_class.find_by_id(associated_instance.id).should == associated_instance }
    it "should replace the user on all associations" do
      associations.each do |association|
        associated_instance.send(association).should == substitute_user
      end
    end
  end

  shared_examples_for "created journalized associated object" do
    before do
      User.stub(:current).and_return user # in order to have the content journal created by the user
      associations.each do |association|
        associated_instance.send(association.to_s + "=", user)
      end
      associated_instance.save!

      User.stub(:current).and_return user2
      associated_instance.reload
      associations.each do |association|
        associated_instance.send(association.to_s + "=", user2)
      end
      associated_instance.save!

      user.destroy
      associated_instance.reload
    end

    it { associated_class.find_by_id(associated_instance.id).should == associated_instance }
    it "should keep the current user on all associations" do
      associations.each do |association|
        associated_instance.send(association).should == user2
      end
    end
    it { associated_instance.journals.first.user.should == substitute_user }
    it "should update the first journal" do
      associations.each do |association|
        associated_instance.journals.first.changed_data[association_key association].last.should == substitute_user.id
      end
    end
    it { associated_instance.journals.last.user.should == user2 }
    it "should update the last journal" do
      associations.each do |association|
        associated_instance.journals.last.changed_data[association_key association].first.should == substitute_user.id
        associated_instance.journals.last.changed_data[association_key association].last.should == user2.id
      end
    end
  end

  describe "WHEN the user has created one attachment" do
    let(:associated_instance) { FactoryGirl.build(:attachment) }
    let(:associated_class) { Attachment }
    let(:associations) { [:author] }

    it_should_behave_like "created journalized associated object"
  end

  describe "WHEN the user has updated one attachment" do
    let(:associated_instance) { FactoryGirl.build(:attachment) }
    let(:associated_class) { Attachment }
    let(:associations) { [:author] }

    it_should_behave_like "updated journalized associated object"
  end

  describe "WHEN the user has an issue created and assigned" do
    let(:associated_instance) { FactoryGirl.build(:work_package, :type => project.types.first,
                                                                 :project => project,
                                                                 :status => status) }
    let(:associated_class) { WorkPackage }
    let(:associations) { [:author, :assigned_to, :responsible] }

    it_should_behave_like "created journalized associated object"
  end

  describe "WHEN the user has an issue updated and assigned" do
    let(:associated_instance) { FactoryGirl.build(:work_package, :type => project.types.first,
                                                                 :project => project,
                                                                 :status => status) }
    let(:associated_class) { WorkPackage }
    let(:associations) { [:author, :assigned_to, :responsible] }

    before do
      User.stub(:current).and_return user2
      associated_instance.author = user2
      associated_instance.assigned_to = user2
      associated_instance.responsible = user2
      associated_instance.save!

      User.stub(:current).and_return user # in order to have the content journal created by the user
      associated_instance.reload
      associated_instance.author = user
      associated_instance.assigned_to = user
      associated_instance.responsible = user
      associated_instance.save!

      user.destroy
      associated_instance.reload
    end

    it { associated_class.find_by_id(associated_instance.id).should == associated_instance }
    it "should replace the user on all associations" do
      associated_instance.author.should == substitute_user
      associated_instance.assigned_to.should be_nil
      associated_instance.responsible.should be_nil
    end
    it { associated_instance.journals.first.user.should == user2 }
    it "should update first journal changes" do
      associations.each do |association|
        associated_instance.journals.first.changed_data[association_key association].last.should == user2.id
      end
    end
    it { associated_instance.journals.last.user.should == substitute_user }
    it "should update second journal changes" do
      associations.each do |association|
        associated_instance.journals.last.changed_data[association_key association].last.should == substitute_user.id
      end
    end
  end

  describe "WHEN the user has updated a wiki content" do
    let(:associated_instance) { FactoryGirl.build(:wiki_content) }
    let(:associated_class) { WikiContent}
    let(:associations) { [:author] }

    it_should_behave_like "updated journalized associated object"
  end

  describe "WHEN the user has created a wiki content" do
    let(:associated_instance) { FactoryGirl.build(:wiki_content) }
    let(:associated_class) { WikiContent }
    let(:associations) { [:author] }

    it_should_behave_like "created journalized associated object"
  end

  describe "WHEN the user has created a news" do
    let(:associated_instance) { FactoryGirl.build(:news) }
    let(:associated_class) { News }
    let(:associations) { [:author] }

    it_should_behave_like "created journalized associated object"
  end

  describe "WHEN the user has worked on news" do
    let(:associated_instance) { FactoryGirl.build(:news) }
    let(:associated_class) { News }
    let(:associations) { [:author] }

    it_should_behave_like "updated journalized associated object"
  end

  describe "WHEN the user has created a message" do
    let(:associated_instance) { FactoryGirl.build(:message) }
    let(:associated_class) { Message }
    let(:associations) { [:author] }

    it_should_behave_like "created journalized associated object"
  end

  describe "WHEN the user has worked on message" do
    let(:associated_instance) { FactoryGirl.build(:message) }
    let(:associated_class) { Message }
    let(:associations) { [:author] }

    it_should_behave_like "updated journalized associated object"
  end

  describe "WHEN the user has created a time entry" do
    let(:associated_instance) { FactoryGirl.build(:time_entry, :project => project,
                                                           :work_package => issue,
                                                           :hours => 2,
                                                           :activity => FactoryGirl.create(:time_entry_activity)) }
    let(:associated_class) { TimeEntry }
    let(:associations) { [:user] }

    it_should_behave_like "created journalized associated object"
  end

  describe "WHEN the user has worked on time_entry" do
    let(:associated_instance) { FactoryGirl.build(:time_entry, :project => project,
                                                           :work_package => issue,
                                                           :hours => 2,
                                                           :activity => FactoryGirl.create(:time_entry_activity)) }
    let(:associated_class) { TimeEntry }
    let(:associations) { [:user] }

    it_should_behave_like "updated journalized associated object"
  end

  describe "WHEN the user has commented" do
    let(:news) { FactoryGirl.create(:news, :author => user) }

    let(:associated_instance) { Comment.new(:commented => news,
                                            :comments => "lorem") }

    let(:associated_class) { Comment }
    let(:associations) { [:author] }

    it_should_behave_like "created associated object"
  end

  describe "WHEN the user is a member of a project" do
    before do
      member #saving
      user.destroy
    end

    it { Member.find_by_id(member.id).should be_nil }
    it { Role.find_by_id(role.id).should == role }
    it { Project.find_by_id(project.id).should == project }
  end

  describe "WHEN the user is watching something" do
    let(:watched) { FactoryGirl.create(:work_package, :project => project) }
    let(:watch) { Watcher.new(:user => user,
                              :watchable => watched) }

    before do
      watch.save!

      user.destroy
    end

    it { Watcher.find_by_id(watch.id).should be_nil }
  end

  describe "WHEN the user has a token created" do
    let(:token) { Token.new(:user => user,
                            :action => "feeds",
                            :value => "loremipsum") }

    before do
      token.save!

      user.destroy
    end

    it { Token.find_by_id(token.id).should be_nil }
  end

  describe "WHEN the user has created a private query" do
    let(:query) { FactoryGirl.build(:private_query, :user => user) }

    before do
      query.save!

      user.destroy
    end

    it { Query.find_by_id(query.id).should be_nil }
  end

  describe "WHEN the user has created a public query" do
    let(:associated_instance) { FactoryGirl.build(:public_query) }

    let(:associated_class) { Query }
    let(:associations) { [:user] }

    it_should_behave_like "created associated object"
  end

  describe "WHEN the user has created a changeset" do
    let(:repository) { FactoryGirl.create(:repository) }
    let(:associated_instance) { FactoryGirl.build(:changeset, :repository_id => repository.id,
                                                          :committer => user.login) }

    let(:associated_class) { Changeset }
    let(:associations) { [:user] }

    before do
      Setting.enabled_scm = Setting.enabled_scm << "Filesystem"
    end

    it_should_behave_like "created journalized associated object"
  end

  describe "WHEN the user has updated a changeset" do
    let(:repository) { FactoryGirl.create(:repository) }
    let(:associated_instance) { FactoryGirl.build(:changeset, :repository_id => repository.id,
                                                          :committer => user2.login) }

    let(:associated_class) { Changeset }
    let(:associations) { [:user] }

    before do
      Setting.enabled_scm = Setting.enabled_scm << "Filesystem"
      User.stub(:current).and_return user2
      associated_instance.user = user2
      associated_instance.save!

      User.stub(:current).and_return user # in order to have the content journal created by the user
      associated_instance.reload
      associated_instance.user = user
      associated_instance.save!

      user.destroy
      associated_instance.reload
    end

    it { associated_class.find_by_id(associated_instance.id).should == associated_instance }
    it "should replace the user on all associations" do
      associated_instance.user.should be_nil
    end
    it { associated_instance.journals.first.user.should == user2 }
    it "should update first journal changes" do
      associated_instance.journals.first.changed_data[:user_id].last.should == user2.id
    end
    it { associated_instance.journals.last.user.should == substitute_user }
    it "should update second journal changes" do
      associated_instance.journals.last.changed_data[:user_id].last.should == substitute_user.id
    end
  end

  describe "WHEN the user is responsible for a project" do
    before do
      project.responsible = user
      project.save!
      user.destroy
      project.reload
    end

    it { Project.find_by_id(project.id).should == project }
    it { project.responsible.should be_nil }
  end

  describe "WHEN the user is assigned an issue category" do
    let(:category) { FactoryGirl.build(:category, :assigned_to => user,
                                                          :project => project) }

    before do
      category.save!
      user.destroy
      category.reload
    end

    it { Category.find_by_id(category.id).should == category }
    it { category.assigned_to.should be_nil }
  end
end
