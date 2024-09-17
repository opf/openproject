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
require "rack/test"

RSpec.describe "API v3 Render resource" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) { create(:project, public: false) }
  let(:work_package) { create(:work_package, project:) }
  let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages edit_work_packages] }) }
  let(:content_type) { "text/plain, charset=UTF-8" }
  let(:path) { api_v3_paths.render_markup plain:, link: context }
  let(:context) { nil }

  before do
    login_as(user)
    post path, params, "CONTENT_TYPE" => content_type
  end

  shared_examples_for "valid response" do
    it { expect(subject.status).to eq(200) }

    it { expect(subject.content_type).to eq("text/html") }

    it { expect(subject.body).to be_html_eql(text) }
  end

  describe "markdown" do
    let(:plain) { false }

    describe "#post" do
      subject(:response) { last_response }

      describe "response" do
        describe "valid" do
          context "w/o context" do
            let(:params) do
              "Hello World! This *is* markdown with a " +
                "[link](http://community.openproject.org) and ümläutß."
            end

            it_behaves_like "valid response" do
              let(:text) do
                <<~HTML
                  <p class="op-uc-p">
                    Hello World! This <em>is</em> markdown with a
                    <a href="http://community.openproject.org"
                       target="_top"
                       rel="noopener noreferrer"
                       class="op-uc-link">link</a>
                    and ümläutß.</p>
                HTML
              end
            end
          end

          context "with context" do
            let(:params) { "Hello World! Have a look at ##{work_package.id}" }
            let(:id) { work_package.id }
            let(:href) { "/work_packages/#{id}" }
            let(:text) do
              <<~HTML
                <p class="op-uc-p">
                  Hello World! Have a look at
                  <a class="issue work_package preview-trigger op-uc-link"
                     target="_top"
                     href="#{href}">##{id}</a>
                </p>
              HTML
            end

            context "with work package context" do
              let(:context) { api_v3_paths.work_package work_package.id }

              it_behaves_like "valid response"
            end

            context "with project context" do
              let(:context) { "/api/v3/projects/#{work_package.project_id}" }

              it_behaves_like "valid response"
            end
          end
        end

        describe "invalid" do
          context "content type" do
            let(:content_type) { "application/json" }
            let(:params) do
              { "text" => "Hello World! Have a look at ##{work_package.id}" }.to_json
            end

            it_behaves_like "unsupported content type",
                            I18n.t("api_v3.errors.invalid_content_type",
                                   content_type: "text/plain",
                                   actual: "application/json")
          end

          context "with context" do
            let(:params) { "" }

            describe "work package does not exist" do
              let(:context) { api_v3_paths.work_package -1 }

              it_behaves_like "invalid render context",
                              I18n.t("api_v3.errors.render.context_object_not_found")
            end

            describe "work package not visible" do
              let(:invisible_work_package) { create(:work_package) }
              let(:context) { api_v3_paths.work_package invisible_work_package.id }

              it_behaves_like "invalid render context",
                              I18n.t("api_v3.errors.render.context_object_not_found")
            end

            describe "context does not exist" do
              let(:context) { api_v3_paths.root }

              it_behaves_like "invalid render context",
                              I18n.t("api_v3.errors.render.context_not_parsable")
            end

            describe "unsupported context resource found" do
              let(:context) { api_v3_paths.activity 2 }

              it_behaves_like "invalid render context",
                              I18n.t("api_v3.errors.render.unsupported_context")
            end

            describe "unsupported context version found" do
              let(:context) { "/api/v4/work_packages/2" }

              it_behaves_like "invalid render context",
                              I18n.t("api_v3.errors.render.unsupported_context")
            end
          end
        end
      end
    end
  end

  describe "plain" do
    describe "#post" do
      let(:plain) { true }

      subject(:response) { last_response }

      describe "response" do
        describe "valid" do
          let(:params) { "Hello *World*! Have a look at #1\n\nwith two lines." }

          it_behaves_like "valid response" do
            let(:text) do
              "<p>Hello *World*! Have a look at <a class=\"issue work_package preview-trigger\" href=\"/work_packages/1\">#1</a></p>\n\n<p>with two lines.</p>"
            end
          end
        end
      end
    end
  end
end
