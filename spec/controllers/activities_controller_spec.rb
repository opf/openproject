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

describe ActivitiesController, type: :controller do
  before :each do
    allow(@controller).to receive(:set_localization)

    admin = FactoryGirl.create(:admin)
    allow(User).to receive(:current).and_return admin

    @params = {}
  end

  describe 'index' do
    shared_examples_for 'valid index response' do
      it { expect(response).to be_success }

      it { expect(response).to render_template 'index' }
    end

    describe 'global' do
      let(:work_package) { FactoryGirl.create(:work_package) }
      let!(:journal) {
        FactoryGirl.create(:work_package_journal,
                           journable_id: work_package.id,
                           created_at: 3.days.ago.to_date.to_s(:db),
                           version: Journal.maximum(:version) + 1,
                           data: FactoryGirl.build(:journal_work_package_journal,
                                                   subject: work_package.subject,
                                                   status_id: work_package.status_id,
                                                   type_id: work_package.type_id,
                                                   project_id: work_package.project_id))
      }

      before { get 'index' }

      it_behaves_like 'valid index response'

      it { expect(assigns(:events_by_day)).not_to be_empty }

      describe 'view' do
        render_views

        it do
          assert_tag tag: 'h3',
                     content: /#{3.day.ago.to_date.day}/,
                     sibling: { tag: 'dl',
                                child: { tag: 'dt',
                                         attributes: { class: /work_package/ },
                                         child: { tag: 'a',
                                                  content: /#{ERB::Util.html_escape(work_package.subject)}/ } } }
        end
      end

      describe 'empty filter selection' do
        before { get 'index', apply: true }

        it_behaves_like 'valid index response'

        it { expect(assigns(:events_by_day)).to be_empty }
      end
    end

    describe 'with activated activity module' do
      let(:project) {
        FactoryGirl.create(:project,
                           enabled_module_names: %w[activity wiki])
      }

      it 'renders activity' do
        get 'index', project_id: project.id
        expect(response).to be_success
        expect(response).to render_template 'index'
      end
    end

    describe 'without activated activity module' do
      let(:project) {
        FactoryGirl.create(:project,
                           enabled_module_names: %w[wiki])
      }

      it 'renders 403' do
        get 'index', project_id: project.id
        expect(response.status).to eq(403)
        expect(response).to render_template 'common/error'
      end
    end

    shared_context 'index with params' do
      let(:session_values) { defined?(session_hash) ? session_hash : {} }

      before { get :index, params, session_values }
    end

    describe '#atom_feed' do
      let(:user) { FactoryGirl.create(:user) }
      let(:project) { FactoryGirl.create(:project) }

      context 'work_package' do
        let!(:wp_1) {
          FactoryGirl.create(:work_package,
                             project: project,
                             author: user)
        }

        describe 'global' do
          render_views

          before { get 'index', format: 'atom' }

          it do
            assert_tag tag: 'entry',
                       child: { tag: 'link',
                                attributes: { href: Regexp.new("/work_packages/#{wp_1.id}#") } }
          end
        end

        describe 'list' do
          let!(:wp_2) {
            FactoryGirl.create(:work_package,
                               project: project,
                               author: user)
          }

          let(:params) {
            { project_id: project.id,
              format: :atom }
          }

          include_context 'index with params'

          it { expect(assigns(:items).count).to eq(2) }

          it { expect(response).to render_template('common/feed') }
        end
      end

      context 'boards' do
        let(:board) {
          FactoryGirl.create(:board,
                             project: project)
        }
        let!(:message_1) {
          FactoryGirl.create(:message,
                             board: board)
        }
        let!(:message_2) {
          FactoryGirl.create(:message,
                             board: board)
        }
        let(:params) {
          { project_id: project.id,
            apply: true,
            show_messages: 1,
            format: :atom }
        }

        include_context 'index with params'

        it { expect(assigns(:items).count).to eq(2) }

        it { expect(response).to render_template('common/feed') }
      end
    end

    describe 'user selection' do
      describe 'first activity request' do
        let(:default_scope) { ['work_packages', 'changesets'] }
        let(:params) { {} }

        include_context 'index with params'

        it { expect(assigns(:activity).scope).to match_array(default_scope) }

        it { expect(session[:activity]).to match_array(default_scope) }
      end

      describe 'subsequent activity requests' do
        let(:scope) { [] }
        let(:params) { {} }
        let(:session_hash) { { activity: [] } }

        include_context 'index with params'

        it { expect(assigns(:activity).scope).to match_array(scope) }

        it { expect(session[:activity]).to match_array(scope) }
      end

      describe 'selection with apply' do
        let(:scope) { [] }
        let(:params) { { apply: true } }

        include_context 'index with params'

        it { expect(assigns(:activity).scope).to match_array(scope) }

        it { expect(session[:activity]).to match_array(scope) }
      end
    end
  end
end
