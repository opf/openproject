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
require "rack/test"

RSpec.describe "API v3 Render resource" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  describe "render" do
    subject(:response) { last_response }

    let(:path) { api_v3_paths.render_markup }

    before do
      post path, "Hello World", "CONTENT_TYPE" => "text/plain"
    end

    context "when login_required", with_settings: { login_required: true } do
      it_behaves_like "unauthenticated access"
    end

    context "when not login_required", with_settings: { login_required: false } do
      it "return 410 GONE" do
        expect(subject.status).to be(410)
      end

      context "with plain format" do
        let(:path) { api_v3_paths.render_markup(plain: true) }

        it "return 410 GONE" do
          expect(subject.status).to be(410)
        end
      end
    end
  end
end
