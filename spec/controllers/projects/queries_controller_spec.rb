#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

require "rails_helper"

RSpec.describe Projects::QueriesController do
  shared_let(:user) { create(:user) }

  describe "#show" do
    let(:query) { build_stubbed(:project_query, user:) }

    before do
      scope = instance_double(ActiveRecord::Relation)
      allow(Queries::Projects::ProjectQuery).to receive(:visible).with(user:).and_return(scope)
      allow(scope).to receive(:find).with(query.id.to_s).and_return(query)

      login_as user
    end

    it "redirects to the projects page" do
      get :show, params: { id: query.id }
      expect(response).to redirect_to(projects_path(query_id: query.id))
    end
  end

  describe "#new" do
    it "requires login" do
      get "new"

      expect(response).not_to be_successful
    end

    context "when logged in" do
      let(:query) { build_stubbed(:project_query, user:) }
      let(:query_id) { "42" }
      let(:query_params) { double }

      before do
        allow(controller).to receive(:permitted_query_params).and_return(query_params)
        allow(Queries::Projects::Factory).to receive(:find)
          .with(query_id, user:, params: query_params, duplicate: true).and_return(query)

        login_as user
      end

      it "renders projects/index" do
        get "new", params: { query_id: 42 }

        expect(response).to render_template("projects/index")
      end

      it "passes variables to template" do
        allow(controller).to receive(:render).and_call_original

        get "new", params: { query_id: 42 }

        expect(controller).to have_received(:render).with(include(locals: { query:, state: :edit }))
      end
    end
  end

  describe "#rename" do
    it "requires login" do
      get "rename", params: { id: 42 }

      expect(response).not_to be_successful
    end

    context "when logged in" do
      let(:query) { build_stubbed(:project_query) }
      let(:query_id) { "42" }

      before do
        allow(Queries::Projects::ProjectQuery).to receive(:find).with(query_id).and_return(query)

        login_as user
      end

      it "renders projects/index" do
        get "rename", params: { id: 42 }

        expect(response).to render_template("projects/index")
      end

      it "passes variables to template" do
        allow(controller).to receive(:render).and_call_original

        get "rename", params: { id: 42 }

        expect(controller).to have_received(:render).with(include(locals: { query:, state: :rename }))
      end
    end
  end

  describe "#create" do
    let(:service_class) { Queries::Projects::ProjectQueries::CreateService }

    it "requires login" do
      post "create"

      expect(response).not_to be_successful
    end

    context "when logged in" do
      let(:query) { build_stubbed(:project_query, user:) }
      let(:query_params) { double }
      let(:service_instance) { instance_double(service_class) }
      let(:service_result) { instance_double(ServiceResult, success?: success?, result: query) }
      let(:success?) { true }

      before do
        allow(controller).to receive(:permitted_query_params).and_return(query_params)
        allow(Queries::Projects::Factory).to receive(:find)
          .with(nil, user:, params: query_params, duplicate: true).and_return(query)
        allow(service_class).to receive(:new).with(from: query, user:).and_return(service_instance)
        allow(service_instance).to receive(:call).with(query_params).and_return(service_result)

        login_as user
      end

      it "calls update service on query" do
        post "create"

        expect(service_instance).to have_received(:call).with(query_params)
      end

      context "when service call succeeds" do
        it "redirects to projects" do
          allow(I18n).to receive(:t).with("lists.create.success").and_return("foo")

          post "create"

          expect(flash[:notice]).to eq("foo")
          expect(response).to redirect_to(projects_path(query_id: query.id))
        end
      end

      context "when service call fails" do
        let(:success?) { false }
        let(:errors) { instance_double(ActiveModel::Errors, full_messages: ["something", "went", "wrong"]) }

        before do
          allow(service_result).to receive(:errors).and_return(errors)
        end

        it "renders projects/index" do
          allow(I18n).to receive(:t).with("lists.create.failure", errors: "something\nwent\nwrong").and_return("bar")

          post "create"

          expect(flash[:error]).to eq("bar")
          expect(response).to render_template("projects/index")
        end

        it "passes variables to template" do
          allow(controller).to receive(:render).and_call_original

          post "create"

          expect(controller).to have_received(:render).with(include(locals: { query:, state: :edit }))
        end
      end
    end
  end

  describe "#update" do
    let(:service_class) { Queries::Projects::ProjectQueries::UpdateService }

    it "requires login" do
      put "update", params: { id: 42 }

      expect(response).not_to be_successful
    end

    context "when logged in" do
      let(:query) { build_stubbed(:project_query, user:) }
      let(:query_id) { "42" }
      let(:query_params) { double }
      let(:service_instance) { instance_double(service_class) }
      let(:service_result) { instance_double(ServiceResult, success?: success?, result: query) }
      let(:success?) { true }

      before do
        allow(controller).to receive(:permitted_query_params).and_return(query_params)
        scope = instance_double(ActiveRecord::Relation)
        allow(Queries::Projects::ProjectQuery).to receive(:visible).and_return(scope)
        allow(scope).to receive(:find).with(query_id).and_return(query)
        allow(service_class).to receive(:new).with(model: query, user:).and_return(service_instance)
        allow(service_instance).to receive(:call).with(query_params).and_return(service_result)

        login_as user
      end

      it "calls update service on query" do
        put "update", params: { id: 42 }

        expect(service_instance).to have_received(:call).with(query_params)
      end

      context "when service call succeeds" do
        it "redirects to projects" do
          allow(I18n).to receive(:t).with("lists.update.success").and_return("foo")

          put "update", params: { id: 42 }

          expect(flash[:notice]).to eq("foo")
          expect(response).to redirect_to(projects_path(query_id: query.id))
        end
      end

      context "when service call fails" do
        let(:success?) { false }
        let(:errors) { instance_double(ActiveModel::Errors, full_messages: ["something", "went", "wrong"]) }

        before do
          allow(service_result).to receive(:errors).and_return(errors)
        end

        it "renders projects/index" do
          allow(I18n).to receive(:t).with("lists.update.failure", errors: "something\nwent\nwrong").and_return("bar")

          put "update", params: { id: 42 }

          expect(flash[:error]).to eq("bar")
          expect(response).to render_template("projects/index")
        end

        it "passes variables to template" do
          allow(controller).to receive(:render).and_call_original

          put "update", params: { id: 42 }

          expect(controller).to have_received(:render).with(include(locals: { query:, state: :edit }))
        end
      end
    end
  end

  describe "#publish" do
    let(:service_class) { Queries::Projects::ProjectQueries::PublishService }

    it "requires login" do
      put "publish", params: { id: 42 }

      expect(response).not_to be_successful
    end

    context "when logged in" do
      let(:query) { build_stubbed(:project_query, user:) }
      let(:query_id) { "42" }
      let(:query_params) { { public: true } }
      let(:service_instance) { instance_double(service_class) }
      let(:service_result) { instance_double(ServiceResult, success?: success?, result: query) }
      let(:success?) { true }

      before do
        allow(controller).to receive(:permitted_query_params).and_return(query_params)
        scope = instance_double(ActiveRecord::Relation)
        allow(Queries::Projects::ProjectQuery).to receive(:visible).and_return(scope)
        allow(scope).to receive(:find).with(query_id).and_return(query)
        allow(service_class).to receive(:new).with(model: query, user:).and_return(service_instance)
        allow(service_instance).to receive(:call).with(query_params).and_return(service_result)

        login_as user
      end

      it "calls publish service on query" do
        put "publish", params: { id: 42 }

        expect(service_instance).to have_received(:call).with(query_params)
      end

      context "when service call succeeds" do
        it "redirects to projects" do
          allow(I18n).to receive(:t).with("lists.publish.success").and_return("foo")

          put "publish", params: { id: 42 }

          expect(flash[:notice]).to eq("foo")
          expect(response).to redirect_to(projects_path(query_id: query.id))
        end
      end

      context "when service call fails" do
        let(:success?) { false }
        let(:errors) { instance_double(ActiveModel::Errors, full_messages: ["something", "went", "wrong"]) }

        before do
          allow(service_result).to receive(:errors).and_return(errors)
        end

        it "renders projects/index" do
          allow(I18n).to receive(:t).with("lists.publish.failure", errors: "something\nwent\nwrong").and_return("bar")

          put "publish", params: { id: 42 }

          expect(flash[:error]).to eq("bar")
          expect(response).to render_template("projects/index")
        end

        it "passes variables to template" do
          allow(controller).to receive(:render).and_call_original

          put "update", params: { id: 42 }

          expect(controller).to have_received(:render).with(include(locals: { query:, state: :edit }))
        end
      end
    end
  end

  describe "#unpublish" do
    let(:service_class) { Queries::Projects::ProjectQueries::PublishService }

    it "requires login" do
      put "unpublish", params: { id: 42 }

      expect(response).not_to be_successful
    end

    context "when logged in" do
      let(:query) { build_stubbed(:project_query, user:) }
      let(:query_id) { "42" }
      let(:query_params) { { public: false } }
      let(:service_instance) { instance_double(service_class) }
      let(:service_result) { instance_double(ServiceResult, success?: success?, result: query) }
      let(:success?) { true }

      before do
        allow(controller).to receive(:permitted_query_params).and_return(query_params)
        scope = instance_double(ActiveRecord::Relation)
        allow(Queries::Projects::ProjectQuery).to receive(:visible).and_return(scope)
        allow(scope).to receive(:find).with(query_id).and_return(query)
        allow(service_class).to receive(:new).with(model: query, user:).and_return(service_instance)
        allow(service_instance).to receive(:call).with(query_params).and_return(service_result)

        login_as user
      end

      it "calls publish service on query" do
        put "unpublish", params: { id: 42 }

        expect(service_instance).to have_received(:call).with(query_params)
      end

      context "when service call succeeds" do
        it "redirects to projects" do
          allow(I18n).to receive(:t).with("lists.unpublish.success").and_return("foo")

          put "unpublish", params: { id: 42 }

          expect(flash[:notice]).to eq("foo")
          expect(response).to redirect_to(projects_path(query_id: query.id))
        end
      end

      context "when service call fails" do
        let(:success?) { false }
        let(:errors) { instance_double(ActiveModel::Errors, full_messages: ["something", "went", "wrong"]) }

        before do
          allow(service_result).to receive(:errors).and_return(errors)
        end

        it "renders projects/index" do
          allow(I18n).to receive(:t).with("lists.unpublish.failure", errors: "something\nwent\nwrong").and_return("bar")

          put "unpublish", params: { id: 42 }

          expect(flash[:error]).to eq("bar")
          expect(response).to render_template("projects/index")
        end

        it "passes variables to template" do
          allow(controller).to receive(:render).and_call_original

          put "unpublish", params: { id: 42 }

          expect(controller).to have_received(:render).with(include(locals: { query:, state: :edit }))
        end
      end
    end
  end

  describe "#destroy" do
    let(:service_class) { Queries::Projects::ProjectQueries::DeleteService }

    it "requires login" do
      delete "destroy", params: { id: 42 }

      expect(response).not_to be_successful
    end

    context "when logged in" do
      let(:query) { build_stubbed(:project_query, user:) }
      let(:query_id) { "42" }
      let(:service_instance) { instance_spy(service_class) }

      before do
        scope = instance_double(ActiveRecord::Relation)
        allow(Queries::Projects::ProjectQuery).to receive(:visible).and_return(scope)
        allow(scope).to receive(:find).with(query_id).and_return(query)

        allow(service_class).to receive(:new).with(model: query, user:).and_return(service_instance)

        login_as user
      end

      it "calls delete service on query" do
        delete "destroy", params: { id: 42 }

        expect(service_instance).to have_received(:call)
      end

      it "redirects to projects" do
        delete "destroy", params: { id: 42 }

        expect(response).to redirect_to(:projects)
      end
    end
  end
end
