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

require_relative "../spec_helper"

RSpec.describe "LDAP synchronized filters", :skip_csrf, type: :rails_request do
  let(:admin) { create(:admin) }
  let(:filter) { create(:ldap_synchronized_filter) }

  before do
    login_as(admin)
  end

  describe "DELETE /ldap_groups/synchronized_filters/:ldap_filter_id" do
    it "redirects with 303 See Other" do
      delete ldap_groups_synchronized_filter_path(ldap_filter_id: filter.id)
      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(ldap_groups_synchronized_groups_path)
    end
  end
end
