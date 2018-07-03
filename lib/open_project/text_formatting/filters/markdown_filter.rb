#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module OpenProject::TextFormatting
  module Filters
    class MarkdownFilter < HTML::Pipeline::MarkdownFilter
      # Convert Markdown to HTML using CommonMarker
      def call
        parse_options = %i[LIBERAL_HTML_TAG]

        render_options = %i[GITHUB_PRE_LANG]
        render_options << :HARDBREAKS if context[:gfm] != false

        extensions = context.fetch :commonmarker_extensions,
                                    %i[table strikethrough tagfilter]


        # We need liberal html tags thus parsing and rendering are several steps
        # Check: We may be able to reuse the ast instead of rendering to html and then parsing with nokogiri again.
        ast = CommonMarker.render_doc(text, parse_options, extensions)
        html = ast.to_html(render_options, extensions)
        html.rstrip!

        html
      end
    end
  end
end
