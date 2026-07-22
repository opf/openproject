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

RSpec.describe FrontendAssetHelper do
  describe "#include_frontend_assets" do
    context "when in development or test",
            with_env: { "OPENPROJECT_DISABLE_DEV_ASSET_PROXY" => "" } do
      before do
        allow(Rails.env).to receive(:production?).and_return(false)
        allow(Rails.application.config).to receive(:relative_url_root).and_return("")
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

    # controller.config is an ActiveSupport::InheritableOptions singleton that persists across the
    # whole spec run and falls back to Rails.application.config.relative_url_root when unset
    # (RSpec's `allow(...).to receive(...)` stubs don't affect it here — stylesheet_link_tag reads
    # relative_url_root through a config that resolves the value via its own internal/parent
    # storage, not a Ruby method dispatch a stub could intercept). So it must be saved and restored
    # explicitly via real assignment, and even the "no override" baseline must be pinned to a known
    # value, or these examples become sensitive to whatever RAILS_RELATIVE_URL_ROOT happens to be
    # set to in the shell/CI environment running the suite.
    context "when in production" do
      let(:original_relative_url_root) { controller.config.relative_url_root }

      before do
        allow(Rails.env).to receive(:production?).and_return(true)
        original_relative_url_root # memoize the pre-mutation value before overwriting it below
        controller.config.relative_url_root = ""
      end

      after do
        controller.config.relative_url_root = original_relative_url_root
      end

      it "returns the path to the asset" do
        expect(helper.include_frontend_assets).to match(%r{script src="/assets/frontend/main(.*).js"})
      end

      context "when using relative_url_root" do
        before { controller.config.relative_url_root = "/openproject" }

        it "prepends it to the asset path" do
          expect(helper.include_frontend_assets).to match(%r{script src="/openproject/assets/frontend/main(.*).js"})
        end
      end

      context "when using relative_url_root ending with a slash" do
        before { controller.config.relative_url_root = "/openproject/" }

        it "prepends it to the asset path only once (bug #41428)" do
          expect(helper.include_frontend_assets).to match(%r{script src="/openproject/assets/frontend/main(.*).js"})
        end
      end
    end
  end

  describe "#raw_variable_asset_path" do
    context "when in development or test",
            with_env: { "OPENPROJECT_DISABLE_DEV_ASSET_PROXY" => "" } do
      before do
        allow(Rails.env).to receive(:production?).and_return(false)
        allow(Rails.application.config).to receive(:relative_url_root).and_return("")
      end

      it "returns the proxied frontend server path" do
        expect(helper.raw_variable_asset_path("blocknote.css"))
          .to match(%r{\Ahttp://(frontend-test|localhost):4200/assets/frontend/blocknote(.*)\.css\z})
      end

      context "when using relative_url_root" do
        before do
          allow(Rails.application.config).to receive(:relative_url_root).and_return("/openproject")
        end

        it "prepends it to the proxied path" do
          expect(helper.raw_variable_asset_path("blocknote.css"))
            .to match(%r{\Ahttp://(frontend-test|localhost):4200/openproject/assets/frontend/blocknote(.*)\.css\z})
        end
      end
    end

    context "when in production" do
      before do
        allow(Rails.env).to receive(:production?).and_return(true)
        allow(Rails.application.config).to receive(:relative_url_root).and_return("")
      end

      it "returns a bare root-relative path" do
        expect(helper.raw_variable_asset_path("blocknote.css"))
          .to match(%r{\A/assets/frontend/blocknote(.*)\.css\z})
      end

      context "when using relative_url_root" do
        before do
          allow(Rails.application.config).to receive(:relative_url_root).and_return("/openproject")
        end

        it "prepends it to the raw asset path (regression: BlockNote shadow-DOM stylesheet hrefs)" do
          expect(helper.raw_variable_asset_path("blocknote.css"))
            .to match(%r{\A/openproject/assets/frontend/blocknote(.*)\.css\z})
        end
      end

      context "when using relative_url_root ending with a slash" do
        before do
          allow(Rails.application.config).to receive(:relative_url_root).and_return("/openproject/")
        end

        it "prepends it exactly once (bug #41428-style double-slash)" do
          expect(helper.raw_variable_asset_path("blocknote.css"))
            .to match(%r{\A/openproject/assets/frontend/blocknote(.*)\.css\z})
        end
      end
    end
  end
end
