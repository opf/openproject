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
require_module_spec_helper

RSpec.describe ITSM do
  context "when the help desk was turned on" do
    before { ITSM::HelpdeskUsers::SetUpService.new.call }

    it "finds the help desk user and role" do
      expect(described_class.helpdesk_user).to have_attributes(name: "Help desk", id: Setting.helpdesk_user_id)
      expect(described_class.helpdesk_role).to have_attributes(name: "Help desk", id: Setting.helpdesk_role_id)
    end
  end

  context "when the help desk was not turned on yet" do
    it "finds nothing and creates nothing" do
      expect do
        expect(described_class.helpdesk_user).to be_nil
        expect(described_class.helpdesk_role).to be_nil
      end.not_to change(Principal, :count)
    end
  end
end
