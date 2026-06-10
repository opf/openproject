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
require_module_spec_helper

module Wikis
  module RelationPageLinks
    RSpec.describe CreateContract do
      include_context "ModelContract shared context"
      let(:linkable) { create(:work_package) }
      let(:project) { linkable.project }
      let(:current_user) { create(:user, member_with_permissions: { project => %i(manage_wiki_page_links view_work_packages) }) }
      let(:relation_page_link) { build_stubbed(:relation_wiki_page_link, author: current_user, linkable:) }

      subject(:contract) { described_class.new(relation_page_link, current_user) }

      it_behaves_like "contract is valid"

      context "when creator is not the current user" do
        let(:author) { create(:user, member_with_permissions: { project => %i(manage_wiki_page_links view_work_packages) }) }
        let(:relation_page_link) { build_stubbed(:relation_wiki_page_link, author:, linkable:) }

        include_examples "contract is invalid", author: :invalid
      end

      context "when the provider is inexistent" do
        let(:provider) { InexistentProvider.new }

        before { relation_page_link.provider = provider }

        include_examples "contract is invalid", provider: :does_not_exist
      end
    end
  end
end
