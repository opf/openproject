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

module Import
  module JiraWikiMarkup
    module Nodes
      # Block nodes
      Document = Data.define(:children)
      Heading = Data.define(:level, :children)
      Paragraph = Data.define(:children)
      CodeBlock = Data.define(:language, :params, :content)
      NoformatBlock = Data.define(:params, :content)
      HorizontalRule = Data.define
      List = Data.define(:list_type, :items)
      ListItem = Data.define(:children, :sublist)
      BlockQuote = Data.define(:children)
      MultiLineBlockQuote = Data.define(:lines)
      TableHeaderRow = Data.define(:cells)
      TableDataRow = Data.define(:raw)
      Panel = Data.define(:params, :content)
      BlankLine = Data.define

      # Inline nodes
      Text = Data.define(:content)
      Bold = Data.define(:children)
      Italic = Data.define(:children)
      Strikethrough = Data.define(:children)
      Underline = Data.define(:children)
      Citation = Data.define(:children)
      InlineCode = Data.define(:content)
      Superscript = Data.define(:children)
      Subscript = Data.define(:children)
      Link = Data.define(:text, :url)
      Image = Data.define(:url, :params)
      Mention = Data.define(:username)
      ColorMacro = Data.define(:children)
      Emoticon = Data.define(:key)
      LineBreak = Data.define
      EmDash = Data.define
      EnDash = Data.define
    end
  end
end
