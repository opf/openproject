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
require_relative "markdown/expected_markdown"

RSpec.describe OpenProject::TextFormatting, "OpenProject allowed link protocols" do # rubocop:disable RSpec/SpecFilePathFormat
  include_context "expected markdown modules"

  context "with default link protocols" do
    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          A link to [OpenProject](https://www.openproject.org)
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <p class="op-uc-p">A link to <a href="https://www.openproject.org" rel="noopener noreferrer nofollow" target="_top" class="op-uc-link">OpenProject</a></p>
        EXPECTED
      end
    end

    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          Contact us via [email](mailto:info@openproject.org)
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <p class="op-uc-p">Contact us via <a href="mailto:info@openproject.org" rel="noopener noreferrer nofollow" target="_top" class="op-uc-link">email</a></p>
        EXPECTED
      end
    end

    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          An autolinked data:text/plain;base64,SGVsbG8sIFdvcmxkIQ==.
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <p class="op-uc-p">An autolinked data:text/plain;base64,SGVsbG8sIFdvcmxkIQ==.</p>
        EXPECTED
      end
    end

    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          A link with [custom protocol](ftp://example.org)
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <p class="op-uc-p">A link with <a rel="noopener noreferrer nofollow" target="_top" class="op-uc-link">custom protocol</a></p>
        EXPECTED
      end
    end
  end

  context "with custom allowed protocols", with_settings: { allowed_link_protocols: %w[ftp sftp] } do
    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          A link to [OpenProject](https://www.openproject.org)
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <p class="op-uc-p">A link to <a href="https://www.openproject.org" rel="noopener noreferrer nofollow" target="_top" class="op-uc-link">OpenProject</a></p>
        EXPECTED
      end
    end

    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          A link with [FTP protocol](ftp://example.org)
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <p class="op-uc-p">A link with <a href="ftp://example.org" rel="noopener noreferrer nofollow" target="_top" class="op-uc-link">FTP protocol</a></p>
        EXPECTED
      end
    end

    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          An autolinked ftp://example.org
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <p class="op-uc-p">An autolinked <a href="ftp://example.org" rel="noopener noreferrer nofollow" target="_top" class="op-uc-link">ftp://example.org</a></p>
        EXPECTED
      end
    end

    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          An autolinked ftp://example.org.
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <p class="op-uc-p">An autolinked <a href="ftp://example.org" rel="noopener noreferrer nofollow" target="_top" class="op-uc-link">ftp://example.org</a>.</p>
        EXPECTED
      end
    end

    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          A link with [SFTP protocol](sftp://example.org)
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <p class="op-uc-p">A link with <a href="sftp://example.org" rel="noopener noreferrer nofollow" target="_top" class="op-uc-link">SFTP protocol</a></p>
        EXPECTED
      end
    end

    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          A link with [data protocol](data:text/plain;base64,SGVsbG8sIFdvcmxkIQ==)
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <p class="op-uc-p">A link with <a rel="noopener noreferrer nofollow" target="_top" class="op-uc-link">data protocol</a></p>
        EXPECTED
      end
    end
  end

  context "with data protocol allowed", with_settings: { allowed_link_protocols: %w[data] } do
    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          A link with [data protocol](data:text/plain;base64,SGVsbG8sIFdvcmxkIQ==)
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <p class="op-uc-p">A link with <a href="data:text/plain;base64,SGVsbG8sIFdvcmxkIQ==" rel="noopener noreferrer nofollow" target="_top" class="op-uc-link">data protocol</a></p>
        EXPECTED
      end
    end

    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          An autolinked data:text/plain;base64,SGVsbG8sIFdvcmxkIQ==.
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <p class="op-uc-p">An autolinked <a href="data:text/plain;base64,SGVsbG8sIFdvcmxkIQ==" rel="noopener noreferrer nofollow" target="_top" class="op-uc-link">data:text/plain;base64,SGVsbG8sIFdvcmxkIQ==</a>.</p>
        EXPECTED
      end
    end
  end
end
