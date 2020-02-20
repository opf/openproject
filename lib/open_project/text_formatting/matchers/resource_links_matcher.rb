#-- encoding: UTF-8

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

module OpenProject::TextFormatting
  module Matchers
    # OpenProject links matching
    #
    # Examples:
    #   Issues:
    #     #52 -> Link to issue #52
    #   Changesets:
    #     r52 -> Link to revision 52
    #     commit:a85130f -> Link to scmid starting with a85130f
    #   Documents:
    #     document#17 -> Link to document with id 17
    #     document:Greetings -> Link to the document with title "Greetings"
    #     document:"Some document" -> Link to the document with title "Some document"
    #   Versions:
    #     version#3 -> Link to version with id 3
    #     version:1.0.0 -> Link to version named "1.0.0"
    #     version:"1.0 beta 2" -> Link to version named "1.0 beta 2"
    #   Attachments:
    #     attachment:file.zip -> Link to the attachment of the current object named file.zip
    #   Source files:
    #     source:"some/file" -> Link to the file located at /some/file in the project's repository
    #     source:"some/file@52" -> Link to the file's revision 52
    #     source:"some/file#L120" -> Link to line 120 of the file
    #     source:"some/file@52#L120" -> Link to line 120 of the file's revision 52
    #     export:"some/file" -> Force the download of the file
    #   Forum messages:
    #     message#1218 -> Link to message with id 1218
    #
    #   Links can refer other objects from other projects, using project identifier:
    #     identifier:r52
    #     identifier:document:"Some document"
    #     identifier:version:1.0.0
    #     identifier:source:some/file
    class ResourceLinksMatcher < RegexMatcher
      include ::OpenProject::TextFormatting::Truncation
      # used for the work package quick links
      include WorkPackagesHelper
      # Used for escaping helper 'h()'
      include ERB::Util
      # For route path helpers
      include OpenProject::ObjectLinking
      include OpenProject::StaticRouting::UrlHelpers
      # Rails helper
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::TextHelper
      include ActionView::Helpers::UrlHelper

      def self.regexp
        %r{
          ([[[:space:]]\(,\-\[\>]|^) # Leading string
          (!)? # Escaped marker
          (([a-z0-9\-_]+):)? # Project identifier
          (#{allowed_prefixes.join("|")})? # prefix
          (
            (\#+|r)(\d+) # separator and its identifier
            |
            (:) # or colon separator
            (
              [^"\s<>][^\s<>]*? # And a non-quoted value [10]
              |
              "([^"]+)" # Or a quoted value [11]
            )
          )
          (?=
            (?=
              [[:punct:]]\W # Includes matches of, e.g., source:foo.ext
            )
            |\.\z # Allow matching when string ends with .
            |, # or with ,
            |\) # or with )
            |[[:space:]]
            |\]
            |<
            |$
           )
        }x
      end

      ##
      # Allowed prefix matchers
      def self.allowed_prefixes
        link_handlers
          .map(&:allowed_prefixes)
          .flatten
          .uniq
      end

      ##
      # Link handlers, may be extended by plugins
      def self.link_handlers
        [
          LinkHandlers::WorkPackages,
          LinkHandlers::HashSeparator,
          LinkHandlers::ColonSeparator,
          LinkHandlers::Revisions
        ]
      end

      def self.process_match(m, matched_string, context)
        # Leading string before match
        instance = new(
          matched_string: matched_string,
          leading: m[1],
          escaped: m[2],
          project_prefix: m[3],
          project_identifier: m[4],
          prefix: m[5],
          sep: m[7] || m[9],
          raw_identifier: m[8] || m[10],
          identifier: m[8] || m[11] || m[10],
          context: context
        )

        instance.process
      end

      attr_reader :leading,
                  :matched_string,
                  :escaped,
                  :project_prefix,
                  :project_identifier,
                  :project,
                  :prefix,
                  :sep,
                  :identifier,
                  :raw_identifier,
                  :link,
                  :context

      def initialize(matched_string:, leading:, escaped:, project_prefix:, project_identifier:,
                     prefix:, sep:, raw_identifier:, identifier:, context:)
        # The entire string that was matched
        @matched_string = matched_string
        # Leading string before the link match
        @leading = leading
        # Catches the (!) to disable the parsing of this lnk
        @escaped = escaped
        # Project prefix (?)
        @project_prefix = project_prefix
        # Project identifier for context
        @project_identifier = project_identifier
        # Prefix (r? for revisions)
        @prefix = prefix
        # Separator(:)
        @sep = sep
        # Identifier with quotes (if any)
        @raw_identifier = raw_identifier
        # Identifier of the object with removed quotes (if any)
        @identifier = identifier
        # Text formatting context
        @context = context

        # Override project context for this match
        @project =
          if project_identifier
            Project.visible.find_by(identifier: project_identifier)
          else
            context[:project]
          end
      end

      ##
      # Process the matched string, returning either a link provided by a formatter,
      # or the matched string (minus escaping, if any) if no handler matches, an error occurred,
      # or the string was escaped.
      def process
        @link = nil

        # Allow handling when not escaped
        unless escaped?
          link_from_match
        end

        result
      end

      ##
      # Whether the matched string contains the escape marker (!) , e.g., `!#1234`.
      def escaped?
        @escaped.present?
      end

      private

      ##
      # Build a matching link by asking all handlers
      def link_from_match
        self.class.link_handlers.each do |klazz|
          handler = klazz.new(self, context: context)

          if handler.applicable?
            @link = handler.call
            break
          end
        end
      rescue => e
        Rails.logger.error "Failed link resource handling for #{matched_string}: #{e}"
        Rails.logger.debug { "Backtrace:\n\t#{e.backtrace.join("\n\t")}" }
        # Keep the original string unmatched
        @link = nil
      end

      ##
      # build resulting link
      def result
        leading + (link || "#{project_prefix}#{prefix}#{sep}#{raw_identifier}")
      end
    end
  end
end
