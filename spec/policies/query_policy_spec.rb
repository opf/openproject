#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe QueryPolicy, type: :controller do
  let(:user)    { FactoryGirl.build_stubbed(:user) }
  let(:project) { FactoryGirl.build_stubbed(:project) }
  let(:query)   { FactoryGirl.build_stubbed(:query, project: project, user: user) }

  describe '#allowed?' do
    let(:subject) { described_class.new(user) }

    before do
      # Allow everything by default so that it is spotted
      # if any other permission influences the outcome.
      allow(user).to receive(:allowed_to?).and_return true
    end

    shared_examples 'viewing queries' do |global|
      context "#{ global ? 'in global context' : 'in project context' }" do
        let(:other_user) { FactoryGirl.build_stubbed(:user) }
        if global
          let(:project) { nil }
        end

        it 'is true if the query is public and another user views it' do
          query.is_public = true
          query.user = other_user
          expect(subject.allowed?(query, :show)).to be_truthy
        end

        context 'query belongs to a different user' do
          let(:query) do
            FactoryGirl.build_stubbed(:query,
                                      project: project,
                                      user: user,
                                      is_public: false)
          end

          it 'is true if the query is private and the owner views it' do
            expect(subject.allowed?(query, :show)).to be_truthy
          end

          it 'is false if the query is private and another user views it' do
            query.user = other_user
            expect(subject.allowed?(query, :show)).to be_falsy
          end
        end
      end
    end

    shared_examples 'action on persisted' do |action, global|
      context "for #{action} #{ global ? 'in global context' : 'in project context' }" do
        if global
          let(:project) { nil }
        end

        before do
          allow(query).to receive(:new_record?).and_return false
          allow(query).to receive(:persisted?).and_return true
        end

        it 'is false if the user has no permission in the project' do
          allow(user).to receive(:allowed_to?).and_return false

          expect(subject.allowed?(query, action)).to be_falsy
        end

        it 'is false if the user has the save_query permission in the project ' +
          'AND the query is not persisted' do
          allow(user).to receive(:allowed_to?).with(:save_queries,
                                                    project,
                                                    global: project.nil?)
            .and_return true
          allow(query).to receive(:persisted?).and_return false

          expect(subject.allowed?(query, action)).to be_falsy
        end

        it 'is true if the user has the save_query permission in the project ' +
          'AND it is his query' do
          allow(user).to receive(:allowed_to?).with(:save_queries,
                                                    project,
                                                    global: project.nil?)
            .and_return true
          query.user = user

          expect(subject.allowed?(query, action)).to be_truthy
        end

        it 'is false if the user has the save_query permission in the project ' +
          'AND it is not his query' do
          allow(user).to receive(:allowed_to?).with(:save_queries,
                                                    project,
                                                    global: project.nil?)
            .and_return true

          query.user = FactoryGirl.build_stubbed(:user)

          expect(subject.allowed?(query, action)).to be_falsy
        end

        it 'is false if the user lacks the save_query permission in the project ' +
          'AND it is his query' do
          allow(user).to receive(:allowed_to?).with(:save_queries,
                                                    project,
                                                    global: project.nil?)
            .and_return false

          query.user = user

          expect(subject.allowed?(query, action)).to be_falsy
        end

        it 'is true if the user has the manage_public_query permission in the project ' +
          'AND it is anothers query ' +
          'AND the query is public' do
          allow(user).to receive(:allowed_to?).with(:manage_public_queries,
                                                    project,
                                                    global: project.nil?)
            .and_return true
          query.user = FactoryGirl.build_stubbed(:user)
          query.is_public = true

          expect(subject.allowed?(query, action)).to be_truthy
        end

        it 'is false if the user lacks the manage_public_query permission in the project ' +
          'AND it is anothers query ' +
          'AND the query is public' do
          allow(user).to receive(:allowed_to?).with(:manage_public_queries,
                                                    project,
                                                    global: project.nil?)
            .and_return false
          query.user = FactoryGirl.build_stubbed(:user)
          query.is_public = true

          expect(subject.allowed?(query, action)).to be_falsy
        end

        it 'is false if the user has the manage_public_query permission in the project ' +
          'AND it is anothers query ' +
          'AND the query is not public' do
          allow(user).to receive(:allowed_to?).with(:manage_public_queries,
                                                    project,
                                                    global: project.nil?)
            .and_return true
          query.user = FactoryGirl.build_stubbed(:user)
          query.is_public = false

          expect(subject.allowed?(query, action)).to be_falsy
        end
      end
    end

    shared_examples 'action on unpersisted' do |action, global|
      context "for #{action} #{ global ? 'in global context' : 'in project context' }" do
        if global
          let(:project) { nil }
        end

        before do
          allow(query).to receive(:new_record?).and_return true
          allow(query).to receive(:persisted?).and_return false
        end

        it 'is false if the user has no permission in the project' do
          allow(user).to receive(:allowed_to?).and_return false

          expect(subject.allowed?(query, action)).to be_falsy
        end

        it 'is true if the user has the save_query permission in the project' do
          allow(user).to receive(:allowed_to?).with(:save_queries,
                                                    project,
                                                    global: global)
            .and_return true

          expect(subject.allowed?(query, action)).to be_truthy
        end

        it 'is false if the user has the save_query permission in the project ' +
          'AND the query is persisted' do
          allow(user).to receive(:allowed_to?).with(:save_queries,
                                                    project,
                                                    global: global)
            .and_return true

          allow(query).to receive(:new_record?).and_return false

          expect(subject.allowed?(query, action)).to be_falsy
        end
      end
    end

    shared_examples 'publicize' do |global|
      context "#{ global ? 'in global context' : 'in project context' }" do
        if global
          let(:project) { nil }
        end

        it 'is false if the user has no permission in the project' do
          allow(user).to receive(:allowed_to?).and_return false

          expect(subject.allowed?(query, :publicize)).to be_falsy
        end

        it 'is true if the user has the manage_public_query permission in the project ' +
          'AND it is his query' do
          allow(user).to receive(:allowed_to?).with(:manage_public_queries,
                                                    project,
                                                    global: project.nil?)
            .and_return true

          expect(subject.allowed?(query, :publicize)).to be_truthy
        end

        it 'is false if the user has the manage_public_query permission in the project ' +
          'AND the query is not public ' +
          'AND it is not his query' do
          allow(user).to receive(:allowed_to?).with(:manage_public_queries,
                                                    project,
                                                    global: project.nil?)
            .and_return true
          query.user = FactoryGirl.build_stubbed(:user)
          query.is_public = false

          expect(subject.allowed?(query, :publicize)).to be_falsy
        end
      end
    end

    shared_examples 'depublicize' do |global|
      context "#{ global ? 'in global context' : 'in project context' }" do
        if global
          let(:project) { nil }
        end

        it 'is false if the user has no permission in the project' do
          allow(user).to receive(:allowed_to?).and_return false

          expect(subject.allowed?(query, :depublicize)).to be_falsy
        end

        it 'is true if the user has the manage_public_query permission in the project ' +
          'AND the query belongs to another user' +
          'AND the query is public' do
          allow(user).to receive(:allowed_to?).with(:manage_public_queries,
                                                    project,
                                                    global: project.nil?)
            .and_return true

          query.user = FactoryGirl.build_stubbed(:user)
          query.is_public = true

          expect(subject.allowed?(query, :depublicize)).to be_truthy
        end

        it 'is false if the user has the manage_public_query permission in the project ' +
          'AND the query is not public' do
          allow(user).to receive(:allowed_to?).with(:manage_public_queries,
                                                    project,
                                                    global: project.nil?)
            .and_return true
          query.is_public = false

          expect(subject.allowed?(query, :depublicize)).to be_falsy
        end
      end
    end

    shared_examples 'star' do |global|
      context "#{ global ? 'in global context' : 'in project context' }" do
        if global
          let(:project) { nil }
        end

        it 'is false if the user has no permission in the project' do
          allow(user).to receive(:allowed_to?).and_return false

          expect(subject.allowed?(query, :star)).to be_falsy
        end
      end
    end

    it_should_behave_like 'action on persisted', :update, global: true
    it_should_behave_like 'action on persisted', :update, global: false
    it_should_behave_like 'action on persisted', :destroy, global: true
    it_should_behave_like 'action on persisted', :destroy, global: false
    it_should_behave_like 'action on unpersisted', :create, global: true
    it_should_behave_like 'action on unpersisted', :create, global: false
    it_should_behave_like 'publicize', global: false
    it_should_behave_like 'publicize', global: true
    it_should_behave_like 'depublicize', global: false
    it_should_behave_like 'depublicize', global: true
    it_should_behave_like 'action on persisted', :star, global: false
    it_should_behave_like 'action on persisted', :star, global: true
    it_should_behave_like 'action on persisted', :unstar, global: false
    it_should_behave_like 'action on persisted', :unstar, global: true
    it_should_behave_like 'viewing queries', global: true
    it_should_behave_like 'viewing queries', global: false
  end
end
