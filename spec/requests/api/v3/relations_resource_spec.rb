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

RSpec.describe "API v3 Relation resource" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) { create(:project_with_types) }
  let(:current_user) do
    create(:user, member_with_roles: { project => role })
  end
  let(:permissions) { [] }
  let(:role) { create(:project_role, permissions:) }

  let(:work_package) do
    create(:work_package,
           project:,
           type: project.types.first)
  end
  let(:visible_work_package) do
    create(:work_package,
           project:,
           type: project.types.first)
  end
  let(:invisible_work_package) do
    # will be inside another project
    create(:work_package)
  end
  let(:visible_relation) do
    create(:relation,
           from: work_package,
           to: visible_work_package)
  end
  let(:invisible_relation) do
    create(:relation,
           from: work_package,
           to: invisible_work_package)
  end

  before do
    allow(User).to receive(:current).and_return current_user
  end

  subject(:response) { last_response }

  describe "#get" do
    let(:path) { api_v3_paths.work_package_relations(work_package.id) }

    context "when having the view_work_packages permission" do
      let(:permissions) { [:view_work_packages] }

      before do
        visible_relation
        invisible_relation

        get path
      end

      it_behaves_like "redirect response", 308 do
        let(:location) { "/api/v3/relations?filters=%5B%7B%22involved%22%3A%7B%22operator%22%3A%22%3D%22%2C%22values%22%3A%5B%22#{work_package.id}%22%5D%7D%7D%5D" } # rubocop:disable Layout/LineLength
      end
    end

    context "when not having view_work_packages" do
      let(:permissions) { [] }

      before do
        get path
      end

      it_behaves_like "not found",
                      I18n.t("api_v3.errors.not_found.work_package")
    end
  end
end
