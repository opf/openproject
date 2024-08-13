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
               "code" do
  include_context "expected markdown modules"

  context "inline code" do
    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          this is `some code`
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <p class="op-uc-p">
            this is <code class="op-uc-code">some code</code>
          </p>
        EXPECTED
      end
    end

    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          this is `<Location /redmine>` some code
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <p class="op-uc-p">
            this is <code class="op-uc-code">&lt;Location /redmine&gt;</code> some code
          </p>
        EXPECTED
      end
    end
  end

  context "block code" do
    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          Text before

          ```
           some code
          ```

          Text after
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <p class="op-uc-p">
            Text before
          </p>

          <pre class="op-uc-code-block">
            some code
          </pre>

          <p class="op-uc-p">
            Text after
          </p>
        EXPECTED
      end
    end
  end

  context "code block with language specified" do
    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          Text before

          ```ruby
            def foobar
              some ruby code
            end
          ```

          Text after
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <p class="op-uc-p">
            Text before
          </p>

          <pre lang="ruby" class="highlight highlight-ruby op-uc-code-block">
            <span class="k">def</span> <span class="nf">foobar</span>
            <span class="n">some</span> <span class="n">ruby</span> <span class="n">code</span>
            <span class="k">end</span>
          </pre>

          <p class="op-uc-p">
            Text after
          </p>
        EXPECTED
      end
    end
  end

  context "blubs" do
    it_behaves_like "format_text produces" do
      let(:raw) do
        "\n\n    git clone git@github.com:opf/openproject.git\n\n"
      end

      let(:expected) do
        <<~EXPECTED
          <pre class="op-uc-code-block">
            git clone git@github.com:opf/openproject.git
          </pre>
        EXPECTED
      end
    end
  end
end
