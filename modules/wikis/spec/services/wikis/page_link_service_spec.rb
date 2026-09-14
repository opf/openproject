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
require_module_spec_helper

RSpec.describe Wikis::PageLinkService do
  subject(:service) { described_class.new }

  describe "#relation_page_link_keys_for" do
    let(:work_package) { create(:work_package) }
    let(:provider) { create(:internal_wiki_provider) }

    let!(:relation_page_link) do
      create(:relation_wiki_page_link, linkable: work_package, provider:, identifier: "/related")
    end

    before do
      create(:inline_wiki_page_link, linkable: work_package, provider:, identifier: "/inline-only")
      create(:relation_wiki_page_link, provider:, identifier: "/other-work-package")
    end

    it "returns the [provider_id, identifier] keys of the linkable's relation page links" do
      expect(service.relation_page_link_keys_for(linkable: work_package))
        .to eq(Set[[provider.id, "/related"]])
    end
  end
end
