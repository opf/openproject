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

RSpec.describe ActivitiesController do
  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project) }

  current_user { admin }

  before do
    allow(controller).to receive(:set_localization)

    @params = {}
  end

  describe "for GET index" do
    shared_examples_for "valid index response" do
      it { expect(response).to be_successful }

      it { expect(response).to render_template "index" }
    end

    describe "global" do
      let!(:work_package) { create(:work_package, :created_in_past, created_at: 3.days.ago) }

      before { get "index" }

      it_behaves_like "valid index response"

      it { expect(assigns(:events)).not_to be_empty }

      describe "view" do
        render_views

        it do
          assert_select "h3",
                        content: /#{3.days.ago.to_date.day}/,
                        sibling: { tag: "dl",
                                   child: { tag: "dt",
                                            attributes: { class: /work_package/ },
                                            child: { tag: "a",
                                                     content: /#{ERB::Util.html_escape(work_package.subject)}/ } } }
        end
      end

      describe "empty filter selection" do
        before do
          get "index", params: { event_types: [""] }
        end

        it_behaves_like "valid index response"

        it { expect(assigns(:events)).to be_empty }
      end

      describe "for a user that sees no projects" do
        current_user { create(:user) }

        it "renders 404" do
          get "index"
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    describe "with activated activity module" do
      let(:project) do
        create(:project,
               enabled_module_names: %w[activity wiki])
      end

      it "renders activity" do
        get "index", params: { project_id: project.id }
        expect(response).to be_successful
        expect(response).to render_template "index"
      end
    end

    describe "without activated activity module" do
      let(:project) do
        create(:project,
               enabled_module_names: %w[wiki])
      end

      it "renders 403" do
        get "index", params: { project_id: project.id }
        expect(response).to have_http_status(:forbidden)
        expect(response).to render_template "common/error"
      end
    end

    shared_context "for GET index with params" do
      let(:session_values) { defined?(session_hash) ? session_hash : {} }

      before { get :index, params:, session: session_values }
    end

    describe "#atom_feed" do
      let(:user) { create(:user) }
      let(:project) { create(:project) }

      context "with work packages" do
        let!(:wp1) do
          create(:work_package,
                 project:,
                 author: user)
        end

        describe "global" do
          render_views

          before { get "index", format: "atom" }

          it "contains a link to the work package" do
            assert_select "entry",
                          child: { tag: "link",
                                   attributes: { href: Regexp.new("/work_packages/#{wp1.id}#") } }
          end
        end

        describe "list" do
          let!(:wp2) do
            create(:work_package,
                   project:,
                   author: user)
          end

          let(:params) do
            { project_id: project.id,
              event_types: [:work_packages],
              format: :atom }
          end

          include_context "for GET index with params"

          it { expect(assigns(:items).pluck(:event_type)).to match_array(%w[work_package-edit work_package-edit]) }

          it { expect(response).to render_template("common/feed") }
        end
      end

      context "with forums" do
        let(:forum) do
          create(:forum,
                 project:)
        end
        let!(:message1) do
          create(:message,
                 forum:)
        end
        let!(:message2) do
          create(:message,
                 forum:)
        end
        let(:params) do
          { project_id: project.id,
            event_types: [:messages],
            format: :atom }
        end

        include_context "for GET index with params"

        it { expect(assigns(:items).pluck(:event_type)).to match_array(%w[message message]) }

        it { expect(response).to render_template("common/feed") }
      end
    end

    describe "user selection" do
      describe "first activity request" do
        let(:default_scope) { ["work_packages", "changesets"] }
        let(:params) { {} }

        include_context "for GET index with params"

        it { expect(assigns(:activity).scope).to match_array(default_scope) }

        it { expect(session[:activity][:scope]).to match_array(default_scope) }

        it { expect(session[:activity][:with_subprojects]).to be(true) }
      end

      describe "subsequent activity requests" do
        let(:scope) { [] }
        let(:params) { {} }
        let(:session_hash) { { activity: { scope: [], with_subprojects: true } } }

        include_context "for GET index with params"

        it { expect(assigns(:activity).scope).to match_array(scope) }

        it { expect(session[:activity][:scope]).to match_array(scope) }

        it { expect(session[:activity][:with_subprojects]).to be(true) }
      end

      describe "selection with apply" do
        let(:scope) { [] }
        let(:params) { { event_types: [""], with_subprojects: 0 } }

        include_context "for GET index with params"

        it { expect(assigns(:activity).scope).to match_array(scope) }

        it { expect(session[:activity][:scope]).to match_array(scope) }

        it { expect(session[:activity][:with_subprojects]).to be(false) }
      end
    end
  end
end
