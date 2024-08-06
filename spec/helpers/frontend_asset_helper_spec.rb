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

RSpec.describe FrontendAssetHelper do
  describe "#include_frontend_assets" do
    context "when in development or test",
            with_env: { "OPENPROJECT_DISABLE_DEV_ASSET_PROXY" => "" } do
      before do
        allow(Rails.env).to receive(:production?).and_return(false)
      end

      it "returns the proxied frontend server" do
        expect(helper.include_frontend_assets).to match(%r{script src="http://(frontend-test|localhost):4200/assets/frontend/main(.*).js"})
      end

      context "when using relative_url_root" do
        before do
          allow(Rails.application.config).to receive(:relative_url_root).and_return("/openproject")
        end

        it "prepends it to the asset path" do
          expect(helper.include_frontend_assets).to match(%r{script src="http://(frontend-test|localhost):4200/openproject/assets/frontend/main(.*).js"})
        end
      end
    end

    context "when in production" do
      before do
        allow(Rails.env).to receive(:production?).and_return(true)
      end

      it "returns the path to the asset" do
        expect(helper.include_frontend_assets).to match(%r{script src="/assets/frontend/main(.*).js"})
      end

      context "when using relative_url_root" do
        before do
          controller.config.relative_url_root = "/openproject"
        end

        it "prepends it to the asset path" do
          expect(helper.include_frontend_assets).to match(%r{script src="/openproject/assets/frontend/main(.*).js"})
        end
      end

      context "when using relative_url_root ending with a slash" do
        before do
          controller.config.relative_url_root = "/openproject/"
        end

        it "prepends it to the asset path only once (bug #41428)" do
          expect(helper.include_frontend_assets).to match(%r{script src="/openproject/assets/frontend/main(.*).js"})
        end
      end
    end
  end
end
