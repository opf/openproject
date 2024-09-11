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
require_relative "expected_markdown"

RSpec.describe OpenProject::TextFormatting,
               "user provided links" do
  include_context "expected markdown modules"

  context "hardened against tabnabbing" do
    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          this is a <a style="display:none;" target="_top" href="http://malicious">
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <p class="op-uc-p">
            this is a <a href="http://malicious" target="_top" rel="noopener noreferrer" class="op-uc-link">
          </p>
        EXPECTED
      end
    end
  end

  context "autolinks" do
    context "for urls" do
      it_behaves_like "format_text produces" do
        let(:raw) do
          <<~RAW
            Autolink to http://www.google.com
          RAW
        end

        let(:expected) do
          <<~EXPECTED
            <p class="op-uc-p">
              Autolink to <a href="http://www.google.com" rel="noopener noreferrer" target="_top" class="op-uc-link">http://www.google.com</a>
            </p>
          EXPECTED
        end
      end
    end

    context "for email addresses" do
      it_behaves_like "format_text produces" do
        let(:raw) do
          <<~RAW
            Mailto link to foo@bar.com
          RAW
        end

        let(:expected) do
          <<~EXPECTED
            <p class="op-uc-p">
              Mailto link to <a href="mailto:foo@bar.com" rel="noopener noreferrer" target="_top" class="op-uc-link">foo@bar.com</a>
            </p>
          EXPECTED
        end
      end
    end
  end

  context "relative URLS" do
    context "path_only is true (default)" do
      it_behaves_like "format_text produces" do
        let(:raw) do
          <<~RAW
            Link to [relative path](/foo/bar)
          RAW
        end

        let(:expected) do
          <<~EXPECTED
            <p class="op-uc-p">
              Link to <a href="/foo/bar" target="_top" class="op-uc-link" rel="noopener noreferrer">relative path</a>
            </p>
          EXPECTED
        end
      end
    end

    context "path_only is false", with_settings: { host_name: "openproject.org" } do
      let(:options) { { only_path: false } }

      it_behaves_like "format_text produces" do
        let(:raw) do
          <<~RAW
            Link to [relative path](/foo/bar)
          RAW
        end

        let(:expected) do
          <<~EXPECTED
            <p class="op-uc-p">
              Link to <a href="http://openproject.org/foo/bar" target="_top" class="op-uc-link" rel="noopener noreferrer">relative path</a>
            </p>
          EXPECTED
        end
      end
    end
  end
end
