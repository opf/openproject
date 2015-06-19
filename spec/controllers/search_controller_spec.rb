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

describe SearchController, type: :controller do
  let!(:project) {
    FactoryGirl.create(:project,
                       name: 'eCookbook')
  }
  let(:user) {
    FactoryGirl.create(:user,
                       member_in_project: project)
  }

  shared_examples_for 'successful search' do
    it { expect(response).to be_success }
    it { expect(response).to render_template('index') }
  end

  before { allow(User).to receive(:current).and_return user }

  describe 'project search' do

    before { get :index }

    it_behaves_like 'successful search'

    context 'search parameter' do
      subject { get :index, q: 'cook' }

      it_behaves_like 'successful search'

      context 'is a work package reference' do
        let!(:work_package) { FactoryGirl.create :work_package, project: project }

        subject { get :index, q: "##{work_package.id}" }

        it { is_expected.to redirect_to work_package }
      end
    end
  end

  describe 'scoped project search' do
    before { get :index, project_id: project.id }

    it_behaves_like 'successful search'

    it { expect(assigns(:project).id).to be(project.id) }
  end

  describe 'work package search' do
    let!(:work_package_1) {
      FactoryGirl.create(:work_package,
                         subject: 'This is a test issue',
                         project: project)
    }
    let!(:work_package_2) {
      FactoryGirl.create(:work_package,
                         subject: 'Issue test 2',
                         project: project,
                         status: FactoryGirl.create(:closed_status))
    }

    before { get :index, q: 'issue', issues: 1 }

    it_behaves_like 'successful search'

    describe '#result' do

      it { expect(assigns(:results).count).to be(2) }

      it { expect(assigns(:results)).to include(work_package_1) }

      it { expect(assigns(:results)).to include(work_package_2) }

      describe '#view' do
        render_views

        it 'marks closed work packages' do
          assert_select 'dt.work_package-closed' do
            assert_select 'a', text: Regexp.new(work_package_2.status.name)
          end
        end
      end
    end

    context 'with first note' do
      let!(:note_1) {
        FactoryGirl.create :work_package_journal,
                           journable_id: work_package_1.id,
                           notes: 'Test note 1',
                           version: 2
      }

      before { allow_any_instance_of(Journal).to receive_messages(predecessor: note_1) }

      context 'and second note' do
        let!(:note_2) {
          FactoryGirl.create :work_package_journal,
                             journable_id: work_package_1.id,
                             notes: 'Special note 2',
                             version: 3
        }

        describe 'second note predecessor' do
          subject { note_2.send :predecessor }

          it { is_expected.to eq note_1 }
          it { expect(note_1.data).not_to be nil }
          it { expect(subject.data).not_to be nil }
        end

        before { get :index, q: 'note', issues: 1 }

        it_behaves_like 'successful search'

        describe '#result' do

          it { expect(assigns(:results).count).to be 1 }

          it { expect(assigns(:results)).to include work_package_1 }

          describe '#view' do
            render_views

            it 'highlights last note' do
              assert_select 'dt.work_package-note + dd' do
                assert_select '.description', text: note_2.notes
              end
            end

            it 'links to work package with anchor to highlighted note' do
              assert_select 'dt.work_package-note' do
                assert_select 'a', href: work_package_path(work_package_1, anchor: 'note-2')
              end
            end
          end
        end
      end
    end
  end

  describe 'helper methods' do
    describe '#scan_query_tokens' do
      subject { @controller.send(:scan_query_tokens, query) }

      context 'with one token' do
        let(:query) { 'word' }

        it { is_expected.to eq %w(word) }

        context 'with double quotes' do
          let(:query) { '"hello world"' }

          it { is_expected.to eq ['hello world'] }
        end
      end

      context 'with multiple tokens' do
        let(:query) { 'hello world something-hyphenated' }

        it { is_expected.to eq %w(hello world something-hyphenated) }

        context 'with double quotes' do
          let(:query) { 'hello "fallen world" something-hyphenated' }

          it { is_expected.to eq ['hello', 'fallen world', 'something-hyphenated'] }
        end
      end
    end

    describe '#scan_work_package_reference' do
      subject { @controller.send(:scan_work_package_reference, query) }

      context 'with normal query' do
        let(:query) { 'lorem' }

        it { is_expected.to be nil }
      end

      context 'with work package reference' do
        let(:query) { '#4123' }

        it { is_expected.not_to be nil }

        describe 'captures' do
          let!(:check_block) { Proc.new { |id| @work_package_id = id } }

          it 'block gets called' do
            # NOTE: this is how it is favored to do in RSpec3
            # expect(check_block).to receive :call
            # but we have only RSpec2 here, so:
            expect(check_block).to receive :call
            @controller.send(:scan_work_package_reference, query, &check_block)
          end

          it 'id inside of block is work package id' do
            @controller.send(:scan_work_package_reference, query, &check_block)

            expect(@work_package_id.to_i).to eq 4123
          end
        end

        context 'and with additional text' do
          let(:query) { '#4123 and some text' }

          it { is_expected.to be nil }
        end
      end
    end
  end
end
