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

require_relative "../../spec_helper"

RSpec.describe LdapDepartments::SynchronizeTreeJob, type: :job do
  let(:tree) { create(:ldap_synchronized_tree) }

  before { allow(LdapDepartments::SynchronizationService).to receive(:synchronize_tree!) }

  context "with the enterprise feature", with_ee: %i[ldap_groups] do
    it "synchronizes the given tree" do
      described_class.perform_now(tree)

      expect(LdapDepartments::SynchronizationService).to have_received(:synchronize_tree!).with(tree)
    end
  end

  context "without the enterprise feature" do
    it "does nothing" do
      described_class.perform_now(tree)

      expect(LdapDepartments::SynchronizationService).not_to have_received(:synchronize_tree!)
    end
  end
end
