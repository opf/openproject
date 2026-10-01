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
require "contracts/shared/model_contract_shared_context"

RSpec.describe Documents::Admin::Settings::CollaborationServerSettingsParamsContract do
  include_context "ModelContract shared context"

  shared_let(:current_user) { create(:admin) }
  let(:setting) { Setting }
  let(:params) { { collaborative_editing_hocuspocus_url: url } }
  let(:url) { "wss://hocuspocus.example.com" }
  let(:contract) do
    described_class.new(setting, current_user, params:)
  end

  it_behaves_like "contract is valid for active admins and invalid for regular users"

  describe "URL scheme validation" do
    context "with a valid wss:// URL" do
      let(:url) { "wss://hocuspocus.example.com" }

      include_examples "contract is valid"
    end

    context "with a valid ws:// URL" do
      let(:url) { "ws://hocuspocus.example.com" }

      include_examples "contract is valid"
    end

    context "with an http:// URL" do
      let(:url) { "http://hocuspocus.example.com" }

      include_examples "contract is invalid",
                       collaborative_editing_hocuspocus_url: :invalid
    end

    context "with an https:// URL" do
      let(:url) { "https://hocuspocus.example.com" }

      include_examples "contract is invalid",
                       collaborative_editing_hocuspocus_url: :invalid
    end

    context "with a completely invalid URL" do
      let(:url) { "not a url at all %%%" }

      include_examples "contract is invalid",
                       collaborative_editing_hocuspocus_url: :invalid
    end

    context "with a blank URL" do
      let(:url) { "" }

      include_examples "contract is valid"
    end

    context "when URL is not provided in params" do
      let(:params) { {} }

      include_examples "contract is valid"
    end
  end
end
