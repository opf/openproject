#-- copyright
# OpenProject My Project Page Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

require 'spec_helper'

describe MyProjectsOverviewsController, type: :controller do
  let(:admin) { FactoryBot.build_stubbed(:admin) }
  let(:project) { FactoryBot.build_stubbed(:project) }

  let(:overview) { double(MyProjectsOverview) }
  let(:custom_block) { %w(a title content) }

  before do
    allow(Project).to receive(:find).and_return(project)
    allow(controller).to receive(:overview).and_return(overview)
    allow(controller).to receive(:set_localization)
    expect(controller).to receive(:authorize)

    allow(User).to receive(:current).and_return admin
  end

  let(:params) { { "id" => project.id.to_s } }

  describe '#index' do
    describe "WHEN calling the page" do
      before do
        get 'index', params: params
      end

      it 'renders the overview page' do
        expect(response).to be_successful
        expect(response).to render_template 'index'
      end
    end

    describe "WHEN calling the page
              WHEN providing a jump parameter" do

      before do
        params["jump"] = "work_packages"
        get 'index', params: params
      end

      it { expect(response).to redirect_to project_work_packages_path(project) }
    end
  end

  describe '#page_layout' do
    before do
      get 'page_layout', params: params
    end

    it 'renders the overview page' do
      expect(response).to be_successful
      expect(response).to render_template 'page_layout'
    end
  end

  describe '#update_custom_element' do
    before do
      params['block_name'] = 'a'
      params['block_title_a'] = 'Title'
      params['textile_a'] = 'Content'
    end

    it 'updates the model' do
      expect(overview).to receive(:save_custom_element).with('a', 'Title', 'Content')
      post :update_custom_element, xhr: true, params: params
    end
  end

  describe '#save_changes' do
    context 'when setting blocks' do
      let(:blockparams) {
        {
          top: 'a,b,c,d',
          left: 'news_latest,members',
          right: 'foobar',
          hidden: 'calendar'
        }
      }

      before do
        expect(overview).to receive(:custom_elements).and_return([custom_block])
        expect(overview).to receive(:top=).with([custom_block])
        expect(overview).to receive(:left=).with(%w(news_latest members))
        expect(overview).to receive(:right=).with(%w())
        expect(overview).to receive(:hidden=).with(%w(calendar))
        expect(overview).to receive(:save).and_return(save_result)
        allow(overview)
          .to receive_message_chain(:errors, :full_messages)
          .and_return(['Some error'])

        post :save_changes, xhr: true, params: params.merge(blockparams)
      end

      context 'save successful' do
        let(:save_result) { true }
        it 'assigns all blocks that exist' do
          expect(controller).to set_flash[:notice].to I18n.t(:notice_successful_update)
          expect(response).to redirect_to(action: :index)
        end
      end

      context 'save erroneous' do
        let(:save_result) { false }
        it 'assigns all blocks that exist' do
          expect(response).to be_successful
          expect(controller).to set_flash[:error].to "The changes could not be saved: Some error"
          expect(response).to render_template('page_layout')
        end
      end
    end
  end

  describe '#add_block' do
    context 'regular block' do
      render_views

      it 'renders that block' do
        post :add_block, xhr: true, params: params.merge(block: 'calendar')
        expect(response).to be_successful
        expect(response).to render_template(partial: '_block')
        expect(response).to render_template(partial: 'my_projects_overviews/blocks/_calendar')
      end

      it 'does not render an invalid block' do
        post :add_block, xhr: true, params: params.merge(block: 'doesnotexist')
        expect(response.body).to be_blank
      end
    end

    context 'custom block' do
      let(:hidden) { [] }
      before do
        expect(overview).to receive(:hidden).and_return(hidden)
        expect(overview).to receive(:new_custom_element).and_return(custom_block)
      end

      it 'creates and saves a new custom block' do
        expect(overview).to receive(:save).and_return(true)

        post :add_block, xhr: true, params: params.merge(block: 'custom_element')

        expect(hidden.length).to eq(1)
        expect(response).to be_successful
        expect(response).to render_template(partial: '_block_textilizable')
      end

      it 'fails gracefully when saving results in error' do
        expect(overview).to receive(:save).and_return(false)
        expect(overview)
          .to receive_message_chain(:errors, :full_messages)
          .and_return(["Error 1", "Error 2"])

        post :add_block, xhr: true, params: params.merge(block: 'custom_element')

        expect(response.status).to eq(500)
        expect(response.body).to include("The changes could not be saved: Error 1, Error 2")
      end
    end
  end
end
