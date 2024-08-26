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
require_relative "shared_contract_examples"

RSpec.describe PlaceholderUsers::CreateContract do
  include_context "ModelContract shared context"

  context "without enterprise" do
    let(:placeholder_user) { PlaceholderUser.new(name: "foo") }
    let(:contract) { described_class.new(placeholder_user, current_user) }

    context "when user with global permission" do
      let(:current_user) { create(:user, global_permissions: %i[manage_placeholder_user]) }

      it_behaves_like "contract is invalid", base: :error_enterprise_only
    end

    context "when user with admin permission" do
      let(:current_user) { build_stubbed(:admin) }

      it_behaves_like "contract is invalid", base: :error_enterprise_only
    end
  end

  context "with enterprise", with_ee: %i[placeholder_users] do
    it_behaves_like "placeholder user contract" do
      let(:placeholder_user) { PlaceholderUser.new(name: placeholder_user_name) }
      let(:contract) { described_class.new(placeholder_user, current_user) }
    end
  end
end
