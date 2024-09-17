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
    class MacroFilter < HTML::Pipeline::Filter
      cattr_accessor :registered

      def self.register(*macros)
        self.registered ||= []

        macros.each { |macro| registered << macro }
      end

      def call
        doc.search("macro").each do |macro|
          registered.each do |macro_class|
            next unless macro_applies?(macro_class, macro)

            # If requested to skip macro expansion, do that
            if context[:disable_macro_expansion]
              macro.replace macro_placeholder(macro_class)
              break
            end

            begin
              macro_class.apply(macro, result:, context:)
            rescue StandardError => e
              Rails.logger.error("Failed to insert macro #{macro_class}: #{e} - #{e.message}")
              macro.replace macro_error_placeholder(macro_class, e.message)
            ensure
              # This macro should have applied, even when an error occurred.
              break
            end
          end
        end

        doc
      end

      private

      def macro_error_placeholder(macro_class, message)
        ApplicationController.helpers.content_tag :macro,
                                                  "#{I18n.t(:macro_execution_error,
                                                            macro_name: macro_class.identifier)} (#{message})",
                                                  class: "macro-unavailable",
                                                  data: { macro_name: macro_class.identifier }
      end

      def macro_placeholder(macro_class)
        ApplicationController.helpers.content_tag :macro,
                                                  I18n.t("macros.placeholder", macro_name: macro_class.identifier),
                                                  class: "macro-placeholder",
                                                  data: { macro_name: macro_class.identifier }
      end

      def macro_applies?(macro_class, element)
        ((element["class"] || "").split & Array(macro_class.identifier)).any?
      end
    end
  end
end

OpenProject::TextFormatting::Filters::MacroFilter.register(
  OpenProject::TextFormatting::Filters::Macros::Toc,
  OpenProject::TextFormatting::Filters::Macros::CreateWorkPackageLink,
  OpenProject::TextFormatting::Filters::Macros::IncludeWikiPage,
  OpenProject::TextFormatting::Filters::Macros::EmbeddedTable,
  OpenProject::TextFormatting::Filters::Macros::ChildPages,
  OpenProject::TextFormatting::Filters::Macros::GithubPullRequest
)
