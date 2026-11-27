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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.shared_examples_for "has workspace linked" do |project_spec_variable_name = :workspace|
  let(:link) { :project }
  let(:title) { public_send(project_spec_variable_name).name }
  let(:workspace_visible) { true }
  let(:current_user_admin) { false }

  before do
    allow(public_send(project_spec_variable_name))
      .to receive(:visible?)
            .and_return(workspace_visible)

    allow(current_user)
      .to receive(:admin?)
            .and_return(current_user_admin)
  end

  context "for a project" do
    it_behaves_like "has a titled link" do
      let(:href) { api_v3_paths.project public_send(project_spec_variable_name).id }
      let(:title) { public_send(project_spec_variable_name).name }
    end

    context "if lacking the permissions to see the project" do
      let(:workspace_visible) { false }

      it_behaves_like "has a titled link" do
        let(:href) { API::V3::URN_UNDISCLOSED }
        let(:title) { I18n.t(:"api_v3.undisclosed.#{link}") }
      end
    end

    context "if lacking the permissions to see the project but being an admin (archived)" do
      let(:workspace_visible) { false }
      let(:current_user_admin) { true }

      it_behaves_like "has a titled link" do
        let(:href) { api_v3_paths.project public_send(project_spec_variable_name).id }
        let(:title) { public_send(project_spec_variable_name).name }
      end
    end
  end

  context "for a program" do
    let(project_spec_variable_name) { build_stubbed(:program) }

    it_behaves_like "has a titled link" do
      let(:href) { api_v3_paths.program public_send(project_spec_variable_name).id }
      let(:title) { public_send(project_spec_variable_name).name }
    end

    context "if lacking the permissions to see the program" do
      let(:workspace_visible) { false }

      it_behaves_like "has a titled link" do
        let(:href) { API::V3::URN_UNDISCLOSED }
        let(:title) { I18n.t(:"api_v3.undisclosed.#{link}") }
      end
    end

    context "if lacking the permissions to see the program but being an admin (archived)" do
      let(:workspace_visible) { false }
      let(:current_user_admin) { true }

      it_behaves_like "has a titled link" do
        let(:href) { api_v3_paths.program public_send(project_spec_variable_name).id }
        let(:title) { public_send(project_spec_variable_name).name }
      end
    end
  end

  context "for a portfolio" do
    let(project_spec_variable_name) { build_stubbed(:portfolio) }

    it_behaves_like "has a titled link" do
      let(:href) { api_v3_paths.portfolio public_send(project_spec_variable_name).id }
      let(:title) { public_send(project_spec_variable_name).name }
    end

    context "if lacking the permissions to see the portfolio" do
      let(:workspace_visible) { false }

      it_behaves_like "has a titled link" do
        let(:href) { API::V3::URN_UNDISCLOSED }
        let(:title) { I18n.t(:"api_v3.undisclosed.#{link}") }
      end
    end

    context "if lacking the permissions to see the portfolio but being an admin (archived)" do
      let(:workspace_visible) { false }
      let(:current_user_admin) { true }

      it_behaves_like "has a titled link" do
        let(:href) { api_v3_paths.portfolio public_send(project_spec_variable_name).id }
        let(:title) { public_send(project_spec_variable_name).name }
      end
    end
  end

  context "with neither" do
    let(project_spec_variable_name) { nil }

    it_behaves_like "has an untitled link" do
      let(:href) { nil }
    end
  end
end

RSpec.shared_examples_for "has workspace embedded" do |project_spec_variable_name = :workspace|
  let(:embedded_path) { "_embedded/project" }
  let(:embedded_resource) { public_send(project_spec_variable_name) }
  let(:workspace_visible) { true }
  let(:current_user_admin) { false }

  before do
    allow(public_send(project_spec_variable_name))
      .to receive(:visible?)
            .and_return(workspace_visible)

    allow(current_user)
      .to receive(:admin?)
            .and_return(current_user_admin)
  end

  context "for a project" do
    let(:embedded_resource_type) { "Project" }

    it_behaves_like "has the resource embedded"

    context "when the user is forbidden to see the project" do
      let(:workspace_visible) { false }

      it_behaves_like "has the resource not embedded"
    end

    context "when the user is forbidden to see the project but is admin (project archived)" do
      let(:workspace_visible) { false }
      let(:current_user_admin) { true }

      it_behaves_like "has the resource embedded"
    end
  end

  context "for a program" do
    let(project_spec_variable_name) { build_stubbed(:program) }
    let(:embedded_resource_type) { "Program" }

    it_behaves_like "has the resource embedded"

    context "when the user is forbidden to see the program" do
      let(:workspace_visible) { false }

      it_behaves_like "has the resource not embedded"
    end

    context "when the user is forbidden to see the program but is admin (program archived)" do
      let(:workspace_visible) { false }
      let(:current_user_admin) { true }

      it_behaves_like "has the resource embedded"
    end
  end

  context "for a portfolio" do
    let(project_spec_variable_name) { build_stubbed(:portfolio) }
    let(:embedded_resource_type) { "Portfolio" }

    it_behaves_like "has the resource embedded"

    context "when the user is forbidden to see the portfolio" do
      let(:workspace_visible) { false }

      it_behaves_like "has the resource not embedded"
    end

    context "when the user is forbidden to see the portfolio but is admin (portfolio archived)" do
      let(:workspace_visible) { false }
      let(:current_user_admin) { true }

      it_behaves_like "has the resource embedded"
    end
  end
end
