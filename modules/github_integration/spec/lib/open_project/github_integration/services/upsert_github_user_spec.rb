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

require File.expand_path("../../../../spec_helper", __dir__)

RSpec.describe OpenProject::GithubIntegration::Services::UpsertGithubUser do
  subject(:upsert) { described_class.new.call(params) }

  let(:params) do
    {
      "id" => 123,
      "login" => "test_user",
      "html_url" => "https://github.com/test_user",
      "avatar_url" => "https://github.com/test_user/avatar.jpg"
    }
  end

  it "creates a new github user" do
    expect { upsert }.to change(GithubUser, :count).by(1)

    expect(GithubUser.last).to have_attributes(
      github_id: 123,
      github_login: "test_user",
      github_html_url: "https://github.com/test_user",
      github_avatar_url: "https://github.com/test_user/avatar.jpg"
    )
  end

  context "when a github user with that id already exists" do
    let(:github_user) do
      create(:github_user, github_id: 123, github_avatar_url: "https://github.com/test_user/old_avatar.jpg")
    end

    it "updates the github user" do
      expect { upsert }.to change { github_user.reload.github_avatar_url }
                             .from("https://github.com/test_user/old_avatar.jpg")
                             .to("https://github.com/test_user/avatar.jpg")
    end
  end
end
