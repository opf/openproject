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

describe SearchController, type: :controller do
  shared_let(:project) do
    FactoryBot.create(:project,
                      name: 'eCookbook')
  end

  shared_let(:other_project) do
    FactoryBot.create(:project,
                      name: 'Other project')
  end

  shared_let(:subproject) do
    FactoryBot.create(:project,
                      name: 'Child project',
                      parent: project)
  end

  shared_let(:role) do
    FactoryBot.create(:role, permissions: %i[view_wiki_pages view_work_packages])
  end

  shared_let(:user) do
    FactoryBot.create(:user,
                      member_in_projects: [project, subproject],
                      member_through_role: role)
  end

  shared_let(:wiki_page) do
    FactoryBot.create(:wiki_page,
                      title: "How to solve an issue",
                      wiki: project.wiki)
  end

  shared_let(:work_package_1) do
    FactoryBot.create(:work_package,
                      subject: 'This is a test issue',
                      project: project)
  end

  shared_let(:work_package_2) do
    FactoryBot.create(:work_package,
                      subject: 'Issue test 2',
                      project: project,
                      status: FactoryBot.create(:closed_status))
  end

  shared_let(:work_package_3) do
    FactoryBot.create(:work_package,
                      subject: 'Issue test 3',
                      project: subproject)
  end

  shared_let(:work_package_4) do
    FactoryBot.create(:work_package,
                      subject: 'Issue test 4',
                      project: other_project)
  end

  shared_examples_for 'successful search' do
    it { expect(response).to be_successful }
    it { expect(response).to render_template('index') }
  end

  before { allow(User).to receive(:current).and_return user }

  describe 'project search' do
    context 'without a search parameter' do
      before { get :index }

      it_behaves_like 'successful search'
    end

    context 'search parameter' do
      context 'is a search string' do
        before do
          get :index, params: { q: 'cook' }
        end

        it_behaves_like 'successful search'
      end
    end
  end

  describe 'scoped project search' do
    before { get :index, params: { project_id: project.id } }

    it_behaves_like 'successful search'

    it { expect(assigns(:project).id).to be(project.id) }
  end

  describe 'searching in all modules' do
    context 'when searching in all projects' do
      before { get :index, params: { q: 'issue', scope: 'all' } }

      it_behaves_like 'successful search'

      describe '#result' do
        it { expect(assigns(:results).count).to be(4) }
        it { expect(assigns(:results)).to include(work_package_1) }
        it { expect(assigns(:results)).to include(work_package_2) }
        it { expect(assigns(:results)).to include(work_package_3) }
        it { expect(assigns(:results)).to include(wiki_page) }
        it { expect(assigns(:results)).to_not include(work_package_4) }
      end

      describe '#results_count' do
        it { expect(assigns(:results_count)).to be_a(Hash) }
        it { expect(assigns(:results_count)['work_packages']).to eql(3) }
      end

      describe '#view' do
        render_views

        it 'marks closed work packages' do
          assert_select 'dt.work_package-closed' do
            assert_select 'a', text: Regexp.new(work_package_2.status.name)
          end
        end
      end
    end

    context 'when searching in project and its subprojects' do
      before { get :index, params: { q: 'issue', project_id: project.id, scope: 'subprojects' } }

      it_behaves_like 'successful search'

      describe '#result' do
        it { expect(assigns(:results).count).to be(4) }
        it { expect(assigns(:results)).to include(work_package_1) }
        it { expect(assigns(:results)).to include(work_package_2) }
        it { expect(assigns(:results)).to include(work_package_3) }
        it { expect(assigns(:results)).to include(wiki_page) }
        it { expect(assigns(:results)).to_not include(work_package_4) }
      end
    end

    context 'when searching in project without its subprojects' do
      before { get :index, params: { q: 'issue', project_id: project.id, scope: 'current_project' } }

      it_behaves_like 'successful search'

      describe '#result' do
        it { expect(assigns(:results).count).to be(3) }
        it { expect(assigns(:results)).to include(work_package_1) }
        it { expect(assigns(:results)).to include(work_package_2) }
        it { expect(assigns(:results)).to include(wiki_page) }
        it { expect(assigns(:results)).to_not include(work_package_3) }
        it { expect(assigns(:results)).to_not include(work_package_4) }
      end
    end

    context 'when searching for a note' do
      let!(:note_1) do
        FactoryBot.create :work_package_journal,
                          journable_id: work_package_1.id,
                          notes: 'Test note 1',
                          version: 2
      end

      before { allow_any_instance_of(Journal).to receive_messages(predecessor: note_1) }

      let!(:note_2) do
        FactoryBot.create :work_package_journal,
                          journable_id: work_package_1.id,
                          notes: 'Special note 2',
                          version: 3
      end

      describe 'second note predecessor' do
        subject { note_2.send :predecessor }

        it { is_expected.to eq note_1 }
        it { expect(note_1.data).not_to be nil }
        it { expect(subject.data).not_to be nil }
      end

      before do
        get :index, params: { q: 'note'}
      end

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
  end
end
