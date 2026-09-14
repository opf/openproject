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

require_relative "../support/pages/ifc_models/show_default"
require_relative "../../../../spec/features/views/shared_examples"

RSpec.describe "bcf view management", :js, with_config: { edition: "bim" } do
  let(:project) { create(:project, enabled_module_names: %i[bim work_package_tracking]) }
  let(:bcf_page) { Pages::IfcModels::ShowDefault.new(project) }
  let(:role) do
    create(:project_role,
           permissions: %w[
             view_work_packages
             save_queries
             save_public_queries
             view_ifc_models
             save_bcf_queries
             manage_public_bcf_queries
           ])
  end

  let(:user) do
    create(:user,
           member_with_roles: { project => role })
  end

  let!(:model) do
    create(:ifc_model_minimal_converted,
           project:,
           uploader: user,
           is_default: true)
  end

  before do
    login_as(user)
    bcf_page.visit_and_wait_until_finished_loading!
  end

  it_behaves_like "module specific query view management" do
    let(:module_page) { bcf_page }
    let(:default_name) { "All open" }
    let(:initial_filter_count) { 0 }
  end
end
