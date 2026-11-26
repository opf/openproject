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
      OpenProject::TextFormatting::Filters::UntrustedSourceFilter,
      OpenProject::TextFormatting::Filters::RelativeLinkFilter,
      OpenProject::TextFormatting::Filters::LinkAttributeFilter,
      OpenProject::TextFormatting::Filters::ExternalLinkCaptureFilter,
      OpenProject::TextFormatting::Filters::FigureWrappedFilter
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

    # Element filters run last, in order, as one Selma pass over the
    # generated HTML, or over the Nokogiri tree for document callers.
    ELEMENT_FILTERS = [
      OpenProject::TextFormatting::Filters::BemCssFilter
    ].freeze

    def to_html(text)
      output = render(text).to_s
      return output if context[:plain_text]

      HTMLPipeline.new(sanitization_config: nil, node_filters: element_filters)
                  .call(output, context:).fetch(:output).html_safe # rubocop:disable Rails/OutputSafety
    end

    def to_document(text)
      document = super
      return document if context[:plain_text]

      element_filters.reduce(document) { |decorated, filter| filter.decorate_document(decorated) }
    end

    def filters
      context[:plain_text] ? TEXT_FILTERS : RICH_FILTERS
    end

    def self.format
      :markdown
    end

    private

    def element_filters
      filter_context = context.dup.freeze
      ELEMENT_FILTERS.map { |filter| filter.new(context: filter_context) }
    end
  end
end
