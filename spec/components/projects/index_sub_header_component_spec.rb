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

require "rails_helper"

RSpec.describe Projects::IndexSubHeaderComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:current_user) { build_stubbed(:user) }
  let(:query) { build_stubbed(:project_query) }

  before do
    mock_permissions_for(current_user) do |mock|
      mock.allow_globally *global_permissions
    end

    with_request_url "/projects" do
      render_inline(described_class.new(current_user:, query:))
    end
  end

  describe "add buttons" do
    def self.workspace_types = %i[portfolio program project]

    let(:add_label) { I18n.t(:button_add) }
    let(:portfolio_label) { I18n.t(:label_portfolio) }
    let(:program_label) { I18n.t(:label_program) }
    let(:project_label) { I18n.t(:label_project) }

    subject { page }

    shared_examples "renders buttons" do |expected_types:, upsell: []|
      workspace_types.each do |workspace_type|
        if expected_types.include?(workspace_type)
          it "renders #{workspace_type} add button" do
            label = send("#{workspace_type}_label")
            href = send("new_#{workspace_type}_path")

            expect(subject).to have_link(label, href:)

            link = subject.find_link(label)

            if upsell.include?(workspace_type)
              expect(link).to have_octicon "op-enterprise-addons"
            else
              expect(link).to have_no_octicon "op-enterprise-addons"
            end
          end
        else
          it "doesn't render #{workspace_type} add button" do
            expect(subject).to have_no_link send("#{workspace_type}_label")
          end
        end
      end
    end

    shared_examples "renders no buttons" do
      it { is_expected.to have_no_button add_label }

      include_examples "renders buttons", expected_types: [], upsell: []
    end

    shared_examples "renders add button directly" do |expected_type, upsell:|
      it { is_expected.to have_no_button add_label }

      include_examples "renders buttons", expected_types: [expected_type], upsell: upsell ? [expected_type] : []
    end

    shared_examples "renders add buttons in a pulldown" do |expected_types, upsell:|
      it { is_expected.to have_button add_label }

      context "within pulldown" do
        subject { page.find(:button, add_label).find(:xpath, "..//action-list") }

        include_examples "renders buttons", expected_types:, upsell:
      end
    end

    context "when user has no permissions" do
      let(:global_permissions) { [] }

      include_examples "renders no buttons"
    end

    context "when user has add_portfolios permission" do
      let(:global_permissions) { %i[add_portfolios] }

      context "without enterprise feature enabled", with_ee: [] do
        include_examples "renders add button directly", :portfolio, upsell: true
      end

      context "with enterprise feature enabled", with_ee: :portfolio_management do
        include_examples "renders add button directly", :portfolio, upsell: false
      end
    end

    context "when user has add_programs permission" do
      let(:global_permissions) { %i[add_programs] }

      context "without enterprise feature enabled", with_ee: [] do
        include_examples "renders add button directly", :program, upsell: true
      end

      context "with enterprise feature enabled", with_ee: :portfolio_management do
        include_examples "renders add button directly", :program, upsell: false
      end
    end

    context "when user has add_project permission" do
      let(:global_permissions) { %i[add_project] }

      include_examples "renders add button directly", :project, upsell: false

      context "with enterprise feature enabled", with_ee: :portfolio_management do
        include_examples "renders add button directly", :project, upsell: false
      end
    end

    context "when user has only part (add_project and add_programs) of permissions" do
      let(:global_permissions) { %i[add_project add_programs] }

      context "without enterprise feature enabled", with_ee: [] do
        include_examples "renders add buttons in a pulldown", %i[program project], upsell: %i[program]
      end

      context "with enterprise feature enabled", with_ee: :portfolio_management do
        include_examples "renders add buttons in a pulldown", %i[program project], upsell: []
      end
    end

    context "when user has all permissions" do
      let(:global_permissions) { %i[add_project add_portfolios add_programs] }

      context "without enterprise feature enabled", with_ee: [] do
        include_examples "renders add buttons in a pulldown", workspace_types, upsell: %i[portfolio program]
      end

      context "with enterprise feature enabled", with_ee: :portfolio_management do
        include_examples "renders add buttons in a pulldown", workspace_types, upsell: []
      end
    end
  end
end
