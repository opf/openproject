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
require_relative "markdown/expected_markdown"

RSpec.describe OpenProject::TextFormatting, "script schemes in links" do # rubocop:disable RSpec/SpecFilePathFormat
  include_context "expected markdown modules"

  context "when a script scheme is listed as an allowed link protocol",
          with_settings: { allowed_link_protocols: %w[javascript vbscript data ftp] } do
    it "omits those schemes from the effective protocol list" do
      expect(Setting::AllowedLinkProtocols.all).to include("ftp", "http", "https", "mailto")
      expect(Setting::AllowedLinkProtocols.all).not_to include("javascript", "vbscript", "data")
    end

    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          A link with [click here](javascript:alert(1))
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <p class="op-uc-p">A link with <a rel="noopener noreferrer nofollow" target="_top" class="op-uc-link">click here</a></p>
        EXPECTED
      end
    end

    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          A link with [click here](vbscript:msgbox(1))
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <p class="op-uc-p">A link with <a rel="noopener noreferrer nofollow" target="_top" class="op-uc-link">click here</a></p>
        EXPECTED
      end
    end

    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          A link with [payload](data:text/html,alert(1))
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <p class="op-uc-p">A link with <a rel="noopener noreferrer nofollow" target="_top" class="op-uc-link">payload</a></p>
        EXPECTED
      end
    end

    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          A link with [files](ftp://example.org)
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <p class="op-uc-p">A link with <a href="ftp://example.org" rel="noopener noreferrer nofollow" target="_top" class="op-uc-link">files</a></p>
        EXPECTED
      end
    end
  end
end
