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

module API
  module V3
    module Providers
      RSpec.describe ProviderRepresenter, :rendering do
        let(:xwiki_provider) { build_stubbed(:xwiki_provider) }
        let(:internal_provider) { build_stubbed(:internal_wiki_provider) }
        let(:embed_links) { false }
        let(:current_user) { build_stubbed(:user) }

        let(:represented) { xwiki_provider }
        let(:representer) { described_class.new(represented, current_user:, embed_links:) }

        subject(:rendered) { representer.to_json }

        describe "_links" do
          describe "self" do
            it_behaves_like "has a titled link" do
              let(:link) { "self" }
              let(:href) { "/api/v3/wiki_providers/#{represented.universal_identifier}" }
              let(:title) { represented.name }
            end
          end
        end

        describe "properties" do
          it_behaves_like "property", :name do
            let(:value) { represented.name }
          end

          it_behaves_like "property", :universalIdentifier do
            let(:value) { represented.universal_identifier }
          end

          it_behaves_like "datetime property", :createdAt do
            let(:value) { represented.created_at }
          end

          it_behaves_like "datetime property", :updatedAt do
            let(:value) { represented.updated_at }
          end
        end
      end
    end
  end
end
