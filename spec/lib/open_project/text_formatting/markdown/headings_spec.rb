#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe OpenProject::TextFormatting,
         'headings',
         # Speeds up the spec by avoiding event mailers to be procssed
         with_settings: {notified_events: []} do
  include OpenProject::TextFormatting
  include ERB::Util
  include WorkPackagesHelper # soft-dependency
  include ActionView::Helpers::UrlHelper # soft-dependency
  include ActionView::Context
  include OpenProject::StaticRouting::UrlHelpers

  def controller
    # no-op
  end

  describe '.format_text' do
    shared_examples_for 'bem heading' do |level|
      let(:raw) do
        <<~RAW
          Some text before

          #{'#' * level} the heading

          more text
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <p>Some text before</p>
          <h#{level} class="op-uc-h#{level}" id="the-heading">
            <a class="wiki-anchor icon-paragraph" aria-hidden="true" href="#the-heading"></a>the heading
          </h#{level}>
          <p>more text</p>
        EXPECTED
      end


      subject { format_text(raw) }

      it 'produces the expected output' do
        is_expected
          .to be_html_eql(expected)
      end
    end

    it_behaves_like 'bem heading', 1
    it_behaves_like 'bem heading', 2
    it_behaves_like 'bem heading', 3
    it_behaves_like 'bem heading', 4
    it_behaves_like 'bem heading', 5
    it_behaves_like 'bem heading', 6

    context 'with the heading being in a code bock' do
      shared_examples_for 'unchanged heading' do |level|
        let(:raw) do
          <<~RAW
            Some text before

            ```
            <h#{level}>The heading </h#{level}>

            ```

            more text
          RAW
        end

        let(:expected) do
          <<~EXPECTED
            <p>Some text before</p>

            <pre><code>
            &lt;h#{level}&gt;The heading &lt;/h#{level}&gt;

            </code></pre>

            <p>more text</p>
          EXPECTED
        end


        subject { format_text(raw) }

        it 'produces the expected output' do
          is_expected
            .to be_html_eql(expected)
        end
      end

      it_behaves_like 'unchanged heading', 1
      it_behaves_like 'unchanged heading', 2
      it_behaves_like 'unchanged heading', 3
      it_behaves_like 'unchanged heading', 4
      it_behaves_like 'unchanged heading', 5
      it_behaves_like 'unchanged heading', 6
    end
  end
end
