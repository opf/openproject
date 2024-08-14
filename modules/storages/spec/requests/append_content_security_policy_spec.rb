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

RSpec.describe "Appendix of default CSP for external file storage hosts" do
  def parse_csp(csp_string)
    csp_string
      .split("; ")
      .map(&:split)
      .each_with_object({}) { |csp_part, csp_hash_map| csp_hash_map[csp_part[0]] = csp_part[1..] }
  end

  shared_let(:project) { create(:project) }
  shared_let(:storage) { create(:nextcloud_storage) }
  shared_let(:project_storage) { create(:project_storage, project:, storage:) }

  describe "GET /" do
    context "when logged in" do
      current_user { create(:user, member_with_permissions: { project => %i[manage_file_links] }) }

      it "appends storage host to the connect-src CSP" do
        get "/"

        csp = parse_csp(last_response.headers["Content-Security-Policy"])
        expect(csp["connect-src"]).to include(storage.host.chomp("/"))
      end
    end

    context "when not logged in" do
      it "does not append host to connect-src CSP" do
        get "/"

        csp = parse_csp(last_response.headers["Content-Security-Policy"])
        expect(csp["connect-src"]).not_to include(storage.host.chomp("/"))
      end
    end
  end
end
