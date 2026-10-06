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

module OpenProject::TextFormatting
  module Filters
    # Code blocks nested in a table reach the pipeline as raw HTML, so CommonMarker
    # never applies `github_pre_lang` to them. Promote the language marker onto the
    # `pre` before SanitizationFilter drops the class and unwraps the `code`.
    class MermaidFilter < HTML::Pipeline::Filter
      LANGUAGE = "mermaid"

      def call
        doc.search("pre > code").each do |code|
          code.parent["lang"] = LANGUAGE if mermaid?(code)
        end

        doc
      end

      private

      def mermaid?(code)
        code["class"].to_s.split.include?("language-#{LANGUAGE}")
      end
    end
  end
end
