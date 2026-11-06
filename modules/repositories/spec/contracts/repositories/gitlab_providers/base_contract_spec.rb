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
require "contracts/shared/model_contract_shared_context"

RSpec.describe Repositories::GitlabProviders::BaseContract do
  include_context "ModelContract shared context"

  let(:current_user) { build_stubbed(:admin) }
  let(:provider) { build(:repository_provider, url: "https://gitlab.example.com") }
  let(:contract) { described_class.new(provider, current_user) }

  it_behaves_like "contract is valid"

  context "when the user is not an admin" do
    let(:current_user) { build_stubbed(:user) }

    it_behaves_like "contract is invalid", base: :error_unauthorized
  end

  context "without a URL" do
    before { provider.url = "" }

    it_behaves_like "contract is invalid", url: :blank
  end

  context "with an invalid URL" do
    before { provider.url = "not a url" }

    it_behaves_like "contract is invalid", url: :url
  end

  context "with the URL of another provider differing only in case and trailing slash" do
    before { create(:repository_provider, url: "https://GitLab.example.com/") }

    it_behaves_like "contract is invalid", url: :taken
  end

  context "when updating a provider without changing its URL" do
    let(:provider) { create(:repository_provider, url: "https://gitlab.example.com") }

    it_behaves_like "contract is valid"
  end

  context "with a webhook user" do
    let(:user) { create(:user) }

    before { provider.gitlab_user_id = user.id }

    it_behaves_like "contract is valid"
  end

  context "with a webhook user that does not exist" do
    before { provider.gitlab_user_id = 0 }

    it_behaves_like "contract is invalid", gitlab_user_id: :does_not_exist
  end
end
