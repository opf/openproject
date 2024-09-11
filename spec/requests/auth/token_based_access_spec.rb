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

RSpec.describe "Token based access", type: :rails_request, with_settings: { login_required?: false } do
  let(:work_package) { create(:work_package) }
  let(:user) do
    create(:user,
           member_with_permissions: { work_package.project => %i[view_work_packages] })
  end
  let(:rss_key) { user.rss_key }

  it "grants access but does not login the user" do
    # work_packages of a private project
    get "/work_packages/#{work_package.id}.atom"
    expect(response)
      .to redirect_to(signin_path(back_url: "http://#{Setting.host_name}/work_packages/#{work_package.id}"))

    # access is possible with a token
    get "/work_packages/#{work_package.id}.atom?key=#{rss_key}"
    expect(response.body)
      .to include("<title>OpenProject - #{work_package}</title>")

    # but for the next request, the user is not logged in
    get "/work_packages/#{work_package.id}"
    expect(response)
      .to redirect_to(signin_path(back_url: "http://#{Setting.host_name}/work_packages/#{work_package.id}"))
  end
end
