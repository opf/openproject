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

describe Project::Copy, type: :model do
  describe '#copy' do
    let(:project) { FactoryGirl.create(:project_with_types) }
    let(:copy) { Project.new }

    before do
      copy.name = 'foo'
      copy.identifier = 'foo'
      copy.copy(project)
    end

    subject { copy }

    it 'should be able to be copied' do
      expect(copy).to be_valid
      expect(copy).not_to be_new_record
    end
  end

  describe '#copy_attributes' do
    let(:project) { FactoryGirl.create(:project_with_types) }

    let(:copy) do
      copy = Project.new
      copy.name = 'foo'
      copy.identifier = 'foo'
      copy
    end

    before do
      copy.send :copy_attributes, project
      copy.save
    end

    describe '#types' do
      subject { copy.types }

      it { is_expected.to eq(project.types) }
    end

    describe '#work_package_custom_fields' do
      let(:project) do
        project = FactoryGirl.create(:project_with_types)
        work_package_custom_field = FactoryGirl.create(:work_package_custom_field)
        project.work_package_custom_fields << work_package_custom_field
        project.save
        project
      end

      subject { copy.work_package_custom_fields }

      it { is_expected.to eq(project.work_package_custom_fields) }
    end

    describe '#is_public' do
      describe '#non_public' do
        let(:project) do
          project = FactoryGirl.create(:project_with_types)
          project.is_public = false
          project.save
          project
        end

        subject { copy.is_public }

        it { expect(copy.is_public?).to eq(project.is_public?) }
      end

      describe '#public' do
        let(:project) do
          project = FactoryGirl.create(:project_with_types)
          project.is_public = true
          project.save
          project
        end

        subject { copy.is_public }

        it { expect(copy.is_public?).to eq(project.is_public?) }
      end
    end
  end

  describe '#copy_associations' do
    let(:project) { FactoryGirl.create(:project_with_types) }
    let(:copy) do
      copy = Project.new
      copy.name = 'foo'
      copy.identifier = 'foo'
      copy.copy_attributes(project)
      copy.save
      copy
    end

    describe '#copy_work_packages' do
      let(:work_package) { FactoryGirl.create(:work_package, project: project) }
      let(:work_package2) { FactoryGirl.create(:work_package, project: project) }
      let(:version) { FactoryGirl.create(:version, project: project) }

      describe '#relation' do
        before do
          wp = work_package
          wp2 = work_package2
          FactoryGirl.create(:relation, from: wp, to: wp2)
          [wp, wp2].each do |wp| project.work_packages << wp end

          copy.send :copy_work_packages, project
          copy.save
        end

        it do
          copy.work_packages.each do |wp| expect(wp).to(be_valid) end
          expect(copy.work_packages.count).to eq(project.work_packages.count)
        end
      end

      describe '#parent' do
        before do
          wp = work_package
          wp2 = work_package2
          wp.parent = wp2
          wp.save

          [wp, wp2].each do |wp| project.work_packages << wp end

          copy.send :copy_work_packages, project
          copy.save
        end

        it do
          expect(parent_wp = copy.work_packages.detect(&:parent)).not_to eq(nil)
          expect(parent_wp.parent.project).to eq(copy)
        end
      end

      describe '#category' do
        before do
          wp = work_package
          wp.category = FactoryGirl.create(:category, project: project)
          wp.save

          project.work_packages << wp.reload

          copy.send :copy_categories, project
          copy.send :copy_work_packages, project
          copy.save
        end

        it do
          expect(cat = copy.work_packages[0].category).not_to eq(nil)
          expect(cat.project).to eq(copy)
        end
      end

      describe '#watchers' do
        let(:role) { FactoryGirl.create(:role, permissions: [:view_work_packages]) }
        let(:watcher) { FactoryGirl.create(:user, member_in_project: project, member_through_role: role) }

        describe '#active_watcher' do
          before do
            wp = work_package
            wp.add_watcher watcher
            wp.save

            project.work_packages << wp

            copy.send :copy_members, project
            copy.send :copy_work_packages, project
            copy.save
          end

          it 'does copy active watchers' do
            expect(copy.work_packages[0].watchers.first.user).to eq(watcher)
          end
        end

        describe '#locked_watcher' do
          before do
            user = watcher
            wp = work_package
            wp.add_watcher user
            wp.save

            user.lock!

            project.work_packages << wp

            copy.send :copy_members, project
            copy.send :copy_work_packages, project
            copy.save
          end

          it 'does not copy locked watchers' do
            expect(copy.work_packages[0].watchers).to eq([])
          end
        end
      end
    end

    describe '#copy_timelines' do
      before do
        timeline = FactoryGirl.create(:timeline, project: project)
        # set options to nil, is known to have been buggy
        timeline.send :write_attribute, :options, nil

        copy.send(:copy_timelines, project)
        copy.save
      end

      subject { copy.timelines.count }

      it { is_expected.to eq(project.timelines.count) }
    end

    describe '#copy_queries' do
      before do
        FactoryGirl.create(:query, project: project)

        copy.send(:copy_queries, project)
        copy.save
      end

      subject { copy.queries.count }

      it { is_expected.to eq(project.queries.count) }
    end

    describe '#copy_members' do
      describe '#with_user' do
        before do
          role = FactoryGirl.create(:role)
          user = FactoryGirl.create(:user, member_in_project: project, member_through_role: role)

          copy.send(:copy_members, project)
          copy.save
        end

        subject { copy.members.count }

        it { is_expected.to eq(project.members.count) }
      end

      describe '#with_group' do
        before do
          project.add_member! FactoryGirl.create(:group), FactoryGirl.create(:role)

          copy.send(:copy_members, project)
          copy.save
        end

        subject { copy.principals.count }

        it { is_expected.to eq(project.principals.count) }
      end
    end

    describe '#copy_wiki' do
      before do
        project.wiki = FactoryGirl.create(:wiki, project: project)
        project.save

        copy.send(:copy_wiki, project)
        copy.save
      end

      subject { copy.wiki }

      it { is_expected.not_to eq(nil) }
      it { is_expected.to be_valid }

      describe '#copy_wiki_pages' do
        describe '#dont_copy_wiki_page_without_content' do
          before do
            project.wiki.pages << FactoryGirl.create(:wiki_page)

            copy.send(:copy_wiki_pages, project)
            copy.save
          end

          subject { copy.wiki.pages.count }

          it { is_expected.to eq(0) }
        end

        describe '#copy_wiki_page_with_content' do
          before do
            project.wiki.pages << FactoryGirl.create(:wiki_page_with_content)

            copy.send(:copy_wiki_pages, project)
            copy.save
          end

          subject { copy.wiki.pages.count }

          it { is_expected.to eq(project.wiki.pages.count) }
        end
      end
      describe '#copy_wiki_menu_items' do
        before do
          project.wiki.wiki_menu_items << FactoryGirl.create(:wiki_menu_item_with_parent, wiki: project.wiki)
          copy.send(:copy_wiki_menu_items, project)
          copy.save
        end

        subject { copy.wiki.wiki_menu_items.count }

        it { is_expected.to eq(project.wiki.wiki_menu_items.count) }
      end
    end

    describe '#copy_boards' do
      let(:board) { FactoryGirl.create(:board, project: project) }

      context 'boards are copied' do
        before do
          copy.send(:copy_boards, project)
          copy.save
        end

        subject { copy.boards.count }

        it { is_expected.to eq(project.boards.count) }
      end

      context 'board topics are copied' do
        before do
          topic = FactoryGirl.create(:message, board: board)
          message = FactoryGirl.create(:message, board: board, parent_id: topic.id)

          copy.send(:copy_boards, project)
          copy.save
        end

        it 'should copy topics without replies' do
          expect(copy.boards.first.topics.count).to eq(project.boards.first.topics.count)
          expect(copy.boards.first.messages.count).not_to eq(project.boards.first.messages.count)
        end
      end
    end

    describe '#copy_versions' do
      before do
        FactoryGirl.create(:version, project: project)

        copy.send(:copy_versions, project)
        copy.save
      end

      subject { copy.versions.count }

      it { is_expected.to eq(project.versions.count) }
    end

    describe '#copy_project_associations' do
      let(:project2) { FactoryGirl.create(:project_with_types) }

      describe '#project_a_associations' do
        before do
          FactoryGirl.create(:project_association, project_a: project, project_b: project2)

          copy.send(:copy_project_associations, project)
          copy.save
        end

        subject { copy.send(:project_a_associations).count }

        it { is_expected.to eq(project.send(:project_a_associations).count) }
      end

      describe '#project_b_associations' do
        before do
          FactoryGirl.create(:project_association, project_a: project2, project_b: project)

          copy.send(:copy_project_associations, project)
          copy.save
        end

        subject { copy.send(:project_b_associations).count }

        it { is_expected.to eq(project.send(:project_b_associations).count) }
      end
    end

    describe '#copy_categories' do
      before do
        FactoryGirl.create(:category, project: project)

        copy.send(:copy_categories, project)
        copy.save
      end

      subject { copy.categories.count }

      it { is_expected.to eq(project.categories.count) }
    end
  end
end
