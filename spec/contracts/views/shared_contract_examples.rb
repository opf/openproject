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
require "contracts/shared/model_contract_shared_context"

RSpec.shared_examples_for "view contract" do |disabled_permission_checks|
  include_context "ModelContract shared context"

  let(:current_user) { build_stubbed(:user) }

  before do
    mock_permissions_for(current_user) do |mock|
      mock.allow_in_project *permissions, project: query_project
    end
  end

  let(:view_query) do
    build_stubbed(:query,
                  user: query_user,
                  public: query_public,
                  project: query_project)
  end
  let(:permissions) { %i[view_work_packages save_queries] }
  let(:query_public) { false }
  let(:query_user) { current_user }
  let(:query_visible) { true }
  let(:query_project) { build_stubbed(:project) }

  before do
    next unless view_query

    visible_scope = instance_double(ActiveRecord::Relation)

    allow(Query)
      .to receive(:visible)
            .with(query_user)
            .and_return(visible_scope)

    allow(visible_scope)
      .to receive(:exists?)
            .with(id: view_query.id)
            .and_return(query_visible)
  end

  describe "validation" do
    it_behaves_like "contract is valid"

    context "with the query being nil" do
      let(:view_query) { nil }

      it_behaves_like "contract is invalid", query: :blank
    end

    context "with the query being invisible to the user" do
      let(:query_visible) { false }

      it_behaves_like "contract is invalid", query: :does_not_exist
    end

    context "with the query being private, the user being the query user and having the :save_queries permission" do
      it_behaves_like "contract is valid"
    end

    unless disabled_permission_checks
      context "with the query being private, the user being the query user and not having the :save_queries permission" do
        let(:permissions) { %i[view_work_packages] }

        it_behaves_like "contract is invalid", base: :error_unauthorized
      end

      context "with the query being public, the user being the query user but only having the :save_queries permission" do
        let(:query_public) { true }

        it_behaves_like "contract is invalid", base: :error_unauthorized
      end

      context "with the query being public, the user not being the query user but having the :manage_public_queries permission" do
        let(:query_public) { true }
        let(:permissions) { %i[view_work_packages manage_public_queries] }

        it_behaves_like "contract is valid"
      end
    end
  end

  include_examples "contract reuses the model errors"
end
