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
               "Setting variable" do
  include_context "expected markdown modules"

  describe "attribute label macros" do
    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          Inline reference to variable setting: {{opSetting:host_name}}

          Inline reference to base_url variable: {{opSetting:base_url}}

          [Link with setting]({{opSetting:base_url}}/foo/bar)

          [Saved and transformed link with setting](http://localhost:3000/prefix/%7B%7BopSetting:base_url%7D%7D/foo/bar)

          Inline reference to invalid variable: {{opSetting:smtp_password}}

          Inline reference to missing variable: {{opSetting:does_not_exist}}
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <p class="op-uc-p">
            Inline reference to variable setting: #{OpenProject::StaticRouting::UrlHelpers.host}
          </p>
          <p class="op-uc-p">
            Inline reference to base_url variable: <a href="#{Rails.application.root_url}" target="_top" rel="noopener noreferrer"
               class="op-uc-link">#{Rails.application.root_url}</a>
          </p>
          <p class="op-uc-p">
            <a href="#{Rails.application.root_url}/foo/bar" target="_top" rel="noopener noreferrer"
               class="op-uc-link">Link with setting</a>
          </p>
          <p class="op-uc-p">
            <a href="#{Rails.application.root_url}/foo/bar" target="_top" rel="noopener noreferrer"
               class="op-uc-link">Saved and transformed link with setting</a>
          </p>
          <p class="op-uc-p">
            Inline reference to invalid variable: {{opSetting:smtp_password}}
          </p>
          <p class="op-uc-p">
            Inline reference to missing variable: {{opSetting:does_not_exist}}
          </p>
        EXPECTED
      end
    end
  end
end
