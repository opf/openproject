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
require_module_spec_helper
require_relative "shared_contract_examples"

RSpec.describe Storages::ProjectStorages::CreateContract do
  it_behaves_like "ProjectStorages contract" do
    # current_user, project, storage and other objects defined in the shared_contract_examples
    # that includes all the stuff shared between create and update.
    let(:project_storage) do
      build(
        :project_storage,
        creator: current_user,
        project:,
        storage:
      )
    end
    let(:contract) { described_class.new(project_storage, current_user) }

    subject(:contract) do
      described_class.new(project_storage, current_user)
    end

    context "when checking creator_id" do
      let(:contract) { described_class.new(project_storage, current_user) }
      let(:project_storage) { build(:project_storage, creator:) }
      let(:current_user) { build_stubbed(:admin) }

      before do
        login_as(current_user)
      end

      context "as creator_id == current_user_id" do
        let(:creator) { current_user }

        it_behaves_like "contract is valid"
      end

      context "as creator_id != current_user_id" do
        let(:creator) { build_stubbed(:user) }

        it_behaves_like "contract is invalid", creator: :invalid
      end
    end
  end
end
