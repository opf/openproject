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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require "contracts/shared/model_contract_shared_context"

RSpec.describe Wikis::XWikiProviders::BaseContract do
  include_context "ModelContract shared context"

  let(:wiki_provider) { build_stubbed(:xwiki_provider) }
  let(:contract) { described_class.new(wiki_provider, current_user) }

  it_behaves_like "contract is valid for active admins and invalid for regular users"

  describe "name" do
    let(:current_user) { build_stubbed(:admin) }

    context "when blank" do
      let(:wiki_provider) { build_stubbed(:xwiki_provider, name: "") }

      include_examples "contract is invalid", name: :blank
    end

    context "when too long" do
      let(:wiki_provider) { build_stubbed(:xwiki_provider, name: "x" * 256) }

      include_examples "contract is invalid", name: :too_long
    end
  end

  describe "url" do
    let(:current_user) { build_stubbed(:admin) }

    context "when blank" do
      let(:wiki_provider) { build_stubbed(:xwiki_provider, url: "") }

      include_examples "contract is invalid", url: :blank
    end

    context "when not https" do
      let(:wiki_provider) { build_stubbed(:xwiki_provider, url: "http://xwiki.example.com") }

      include_examples "contract is invalid", url: :url_not_secure_context
    end

    context "when too long" do
      let(:wiki_provider) { build_stubbed(:xwiki_provider, url: "https://#{'x' * 250}.com") }

      include_examples "contract is invalid", url: :too_long
    end
  end
end
