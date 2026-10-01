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

require "spec_helper"
require_module_spec_helper

RSpec.describe OpenProject::GitlabIntegration::Services::UpsertGitlabUser do
  subject(:gitlab_user) { described_class.new.call(payload) }

  let(:email) { "admin@gitlab.com" }

  let(:payload) do
    OpenProject::GitlabIntegration::NotificationHandler::Helper::Payload.new(
      "id" => 1,
      "name" => "Administrator",
      "username" => "root",
      "avatar_url" => "https://www.gravatar.com/avatar/1?s=80&d=identicon",
      "email" => email
    )
  end

  it "stores the user" do
    expect { gitlab_user }.to change(GitlabUser, :count).by(1)
    expect(gitlab_user).to have_attributes(gitlab_id: 1,
                                           gitlab_name: "Administrator",
                                           gitlab_username: "root",
                                           gitlab_avatar_url: "https://www.gravatar.com/avatar/1?s=80&d=identicon")
  end

  context "when the payload carries no email address" do
    let(:email) { nil }

    it "stores the user" do
      expect { gitlab_user }.to change(GitlabUser, :count).by(1)
    end
  end
end
