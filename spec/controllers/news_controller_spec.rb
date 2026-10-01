# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe NewsController do
  render_views

  include BecomeMember

  let!(:news) { create(:news, project: project) }
  let!(:news_in_other_project) { create(:news) }

  shared_let(:project) { create(:project) }
  shared_current_user { create(:admin) }

  describe "#index" do
    context "when requesting the global index" do
      it "renders index" do
        get :index

        expect(response).to be_successful
        expect(response).to render_template "index"

        expect(assigns(:project)).to be_nil
        expect(assigns(:news)).to contain_exactly(news, news_in_other_project)
      end
    end

    context "when requesting the project index" do
      it "renders index with project" do
        get :index, params: { project_id: project.id }

        expect(response).to be_successful
        expect(response).to render_template "index"
        expect(assigns(:news)).to contain_exactly(news)
        expect(assigns(:project)).to eq(project)
      end
    end
  end

  describe "#show" do
    context "when routed through the global news path" do
      it "renders show" do
        get :show, params: { id: news.id }

        expect(response).to be_successful
        expect(response).to render_template "show"

        expect(assigns(:news)).to eq news
        expect(assigns(:project)).to eq news.project
      end
    end

    context "when routed through the project" do
      it "renders show" do
        get :show, params: { project_id: news.project_id, id: news.id }

        expect(response).to be_successful
        expect(response).to render_template "show"

        expect(assigns(:news)).to eq news
      end

      it "renders show with slug" do
        get :show, params: { project_id: news.project_id, id: "#{news.id}-some-news-title" }

        expect(response).to be_successful
        expect(response).to render_template "show"

        expect(assigns(:news)).to eq news
      end

      it "renders error if news item is not found" do
        get :show, params: { project_id: news.project_id, id: -1 }

        expect(response).to be_not_found
      end

      it "renders edit link with correct project identifier" do
        get :show, params: { project_id: news.project_id, id: news.id }

        expect(response.body).to include edit_project_news_path(project, news)
      end
    end
  end

  describe "#new" do
    it "renders new" do
      get :new, params: { project_id: project.id }

      expect(response).to be_successful
      expect(response).to render_template "new"
    end
  end

  describe "#create" do
    context "with news_added notifications" do
      it "persists a news item" do
        become_member(project, current_user)

        post :create,
             params: {
               project_id: project.id,
               news: {
                 title: "NewsControllerTest",
                 description: "This is the description",
                 summary: ""
               }
             }
        expect(response).to redirect_to project_news_index_path(project)

        news = News.find_by!(title: "NewsControllerTest")
        expect(news).not_to be_nil
        expect(news.description).to eq "This is the description"
        expect(news.author).to eq current_user
        expect(news.project).to eq project
      end
    end

    it "doesn't persist if validations fail" do
      post :create,
           params: {
             project_id: project.id,
             news: {
               title: "",
               description: "This is the description",
               summary: ""
             }
           }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).to render_template "new"
      expect(assigns(:news)).not_to be_nil
      expect(assigns(:news)).to be_new_record

      expect(response.body).to have_text /1 error/
    end
  end

  describe "#edit" do
    it "renders edit" do
      get :edit, params: { project_id: news.project_id, id: news.id }
      expect(response).to be_successful
      expect(response).to render_template "edit"
    end
  end

  describe "#update" do
    it "updates the news element" do
      put :update,
          params: { project_id: news.project_id, id: news.id, news: { description: "Description changed by test_post_edit" } }

      expect(response).to redirect_to project_news_path(news.project, news)

      news.reload
      expect(news.description).to eq "Description changed by test_post_edit"
    end
  end

  describe "#destroy" do
    it "deletes the news item and redirects with 303 See Other" do
      delete :destroy, params: { project_id: news.project_id, id: news.id }

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to project_news_index_path(news.project)
      expect { news.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
