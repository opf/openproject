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
               "toc macro" do
  include_context "expected markdown modules"

  it_behaves_like "format_text produces" do
    let(:raw) do
      <<~RAW
        <macro class="embedded-table op-uc-placeholder"
               data-query-props="{&quot;columns[]&quot;:[&quot;id&quot;,&quot;subject&quot;,&quot;type&quot;,&quot;status&quot;,&quot;assignee&quot;,&quot;updatedAt&quot;],&quot;showSums&quot;:false,&quot;timelineVisible&quot;:false,&quot;highlightingMode&quot;:&quot;inline&quot;,&quot;highlightedAttributes[]&quot;:[&quot;/api/v3/queries/columns/status&quot;,&quot;/api/v3/queries/columns/priority&quot;,&quot;/api/v3/queries/columns/dueDate&quot;],&quot;showHierarchies&quot;:true,&quot;groupBy&quot;:&quot;&quot;,&quot;filters&quot;:&quot;[{&quot;status&quot;:{&quot;operator&quot;:&quot;o&quot;,&quot;values&quot;:[]}}]&quot;,&quot;sortBy&quot;:&quot;[[&quot;id&quot;,&quot;asc&quot;]]&quot;}"></macro>
      RAW
    end

    let(:expected) do
      <<~EXPECTED
        <p class="op-uc-p">
          <opce-macro-embedded-table class="embedded-table" data-query-props='{"columns[]":["id","subject","type","status","assignee","updatedAt"],"showSums":false,"timelineVisible":false,"highlightingMode":"inline","highlightedAttributes[]":["/api/v3/queries/columns/status","/api/v3/queries/columns/priority","/api/v3/queries/columns/dueDate"],"showHierarchies":true,"groupBy":"","filters":"[{"status":{"operator":"o","values":[]}}]","sortBy":"[["id","asc"]]"}'></opce-macro-embedded-table>
        </p>
      EXPECTED
    end
  end
end
