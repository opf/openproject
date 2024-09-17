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

require "spec_helper"

RSpec.describe API::Decorators::Single do
  let(:user) { create(:user, member_with_roles: { project => role }) }
  let(:project) { create(:project_with_types) }
  let(:role) { create(:project_role, permissions:) }
  let(:permissions) { [:view_work_packages] }
  let(:model) { Object.new }

  let(:single) { API::Decorators::Single.new(model, current_user: user) }

  describe ".checked_permissions" do
    let(:permissions) { [:add_work_packages] }
    let!(:initial_value) { described_class.checked_permissions }

    after do
      described_class.checked_permissions = initial_value
    end

    it "stores the value" do
      expect(described_class.checked_permissions).to be_nil

      described_class.checked_permissions = permissions

      expect(described_class.checked_permissions).to match_array permissions
    end
  end
end
