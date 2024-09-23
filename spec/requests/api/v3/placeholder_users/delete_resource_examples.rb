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

RSpec.shared_examples "deletion allowed" do
  it "responds with 202" do
    expect(last_response).to have_http_status :accepted
  end

  it "locks the account and mark for deletion" do
    expect(Principals::DeleteJob)
      .to have_been_enqueued
            .with(placeholder)

    expect(placeholder.reload).to be_locked
  end

  context "with a non-existent user" do
    let(:path) { api_v3_paths.placeholder_user 1337 }

    it_behaves_like "not found"
  end
end

RSpec.shared_examples "deletion is not allowed" do
  it "responds with 403" do
    expect(last_response).to have_http_status :forbidden
  end

  it "does not delete the user" do
    expect(PlaceholderUser).to exist(placeholder.id)
  end
end
