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
require "task_list/filter"

module OpenProject::TextFormatting::Formats::Markdown
  class Formatter < OpenProject::TextFormatting::Formats::BaseFormatter
    RICH_FILTERS = [
      OpenProject::TextFormatting::Filters::SettingMacrosFilter,
      OpenProject::TextFormatting::Filters::MarkdownFilter,
      OpenProject::TextFormatting::Filters::SanitizationFilter,
      OpenProject::TextFormatting::Filters::TaskListFilter,
      OpenProject::TextFormatting::Filters::TableOfContentsFilter,
      OpenProject::TextFormatting::Filters::MacroFilter,
      OpenProject::TextFormatting::Filters::MentionFilter,
      OpenProject::TextFormatting::Filters::PatternMatcherFilter,
      OpenProject::TextFormatting::Filters::SyntaxHighlightFilter,
      OpenProject::TextFormatting::Filters::AttachmentFilter,
      OpenProject::TextFormatting::Filters::AutolinkFilter,
      OpenProject::TextFormatting::Filters::AutolinkCustomProtocolsFilter,
      OpenProject::TextFormatting::Filters::RelativeLinkFilter,
      OpenProject::TextFormatting::Filters::LinkAttributeFilter,
      OpenProject::TextFormatting::Filters::ExternalLinkCaptureFilter,
      OpenProject::TextFormatting::Filters::FigureWrappedFilter,
      OpenProject::TextFormatting::Filters::BemCssFilter
    ].freeze

    # `text/plain` mailer bodies share the matcher and mention stages so
    # work-package references resolve consistently with the HTML channel,
    # then `PlainTextOutputFilter` collapses the DOM to text. Filters that
    # only shape HTML (TOC, syntax highlight, autolink, link-attribute,
    # figure, BEM) are omitted because `doc.text` would discard their work.
    TEXT_FILTERS = [
      OpenProject::TextFormatting::Filters::SettingMacrosFilter,
      OpenProject::TextFormatting::Filters::MarkdownFilter,
      OpenProject::TextFormatting::Filters::SanitizationFilter,
      OpenProject::TextFormatting::Filters::MentionFilter,
      OpenProject::TextFormatting::Filters::PatternMatcherFilter,
      OpenProject::TextFormatting::Filters::PlainTextOutputFilter
    ].freeze

    def to_html(text)
      result = pipeline.call(text, context)
      output = result[:output].to_s

      context[:plain_text] ? output : output.html_safe # rubocop:disable Rails/OutputSafety
    end

    def to_document(text)
      pipeline.to_document text, context
    end

    def filters
      context[:plain_text] ? TEXT_FILTERS : RICH_FILTERS
    end

    def self.format
      :markdown
    end
  end
end
