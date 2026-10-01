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
  module Matchers
    # OpenProject links matching
    #
    # Examples:
    #   Work packages:
    #     #52       -> Plain link to work package 52
    #     ##52      -> Inline quickinfo card for work package 52
    #     ###52     -> Detailed quickinfo card for work package 52
    #   Work packages (semantic identifiers, when the instance is in semantic mode):
    #     #PROJ-7   -> Plain link to the work package whose display id is PROJ-7
    #     ##PROJ-7  -> Inline quickinfo card
    #     ###PROJ-7 -> Detailed quickinfo card
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
      # Unscoped label resolution (`lookup`) paired with viewer-scoped
      # link gating (`visible_ids`), so the link handler renders the
      # same label for everyone and decides anchor-vs-text per viewer.
      class WorkPackagePreloadCache
        attr_reader :lookup, :visible_ids

        def initialize(lookup:, visible_ids:)
          @lookup = lookup
          @visible_ids = visible_ids
        end

        def fetch(identifier)
          lookup[identifier.to_s]
        end

        def visible?(work_package_id)
          visible_ids.include?(work_package_id)
        end

        # Frozen singleton, not a factory — callers must not mutate it.
        EMPTY = new(lookup: {}.freeze, visible_ids: Set.new.freeze).freeze
      end

      CACHE_KEY = :text_formatting_work_package_preload_cache
      private_constant :CACHE_KEY

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

      # Hash and revision separators sit on independent alternation branches
      # so semantic ids apply only to `#` references — `r` revisions stay
      # numeric-only.
      def self.regexp
        semantic_id = WorkPackage::SemanticIdentifier::ID_ROUTE_CONSTRAINT.source
        prefixes = allowed_prefixes.join("|")
        %r{
          (?<leading>[[[:space:]](,~\-\[>]|^)
          (?<escaped>!)?
          (?<project_prefix>(?<project_identifier>[a-z0-9\-_]+):)?
          (?<prefix>#{prefixes})?
          (?:
            (?<hash_sep>\#+)(?<hash_id>#{semantic_id})
            |
            (?<rev_sep>r)(?<rev_id>\d+)
            |
            (?<colon_sep>:)(?<colon_value>[^"\s<>][^\s<>]*?|"(?<quoted>[^"]+)")
          )
          (?=
            (?=[[:punct:]]\W) # Includes matches of, e.g., source:foo.ext
            |\.\z|,|~|\)|[[:space:]]|\]|<|$
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

      def self.current_cache
        RequestStore.store[CACHE_KEY] || WorkPackagePreloadCache::EMPTY
      end

      # Save/restore so a nested `format_text` (e.g. a custom-field
      # formatter re-entering the pipeline) doesn't clobber the outer
      # render's cache.
      def self.with_preloaded_resources(doc, context)
        previous = RequestStore.store[CACHE_KEY]
        return yield unless preload_required?(context)

        identifiers = collect_work_package_identifiers(doc)
        return yield if identifiers.empty?

        RequestStore.store[CACHE_KEY] = build_cache(identifiers, context)
        yield
      ensure
        RequestStore.store[CACHE_KEY] = previous
      end

      # Semantic mode needs the row to map `PROJ-7` to an id; static-HTML
      # output needs `type`/`subject` to compose the quickinfo anchor.
      def self.preload_required?(context)
        Setting::WorkPackageIdentifier.semantic? || context[:static_html]
      end
      private_class_method :preload_required?

      def self.collect_work_package_identifiers(doc)
        identifiers = Set.new
        doc.search(".//text()").each do |node|
          next if OpenProject::TextFormatting::PreformattedBlocks.ancestor?(node)

          node.to_s.scan(regexp) do
            extract_work_package_identifier(Regexp.last_match)&.then { identifiers << it }
          end
        end
        identifiers
      end

      # Returns the WP identifier for any `#N` / `##N` / `###N` (or
      # semantic-shape) reference. Returns nil for prefixed resource links
      # (`version#3`, `message#12`) and `:`-separator resources. Leading-zero
      # numerics ("0123") pass through here — the link handler rejects them
      # at render time, so a non-resolving cache entry is harmless.
      def self.extract_work_package_identifier(match)
        parts = parse_match(match)
        identifier = parts[:identifier]
        return nil unless parts[:prefix].nil? && parts[:sep]&.start_with?("#") && identifier.present?

        identifier
      end

      # Two SELECTs in the common case (unscoped fetch + visibility id
      # pluck), a third when historical aliases need resolving. Static-
      # HTML output additionally needs `:type` and `:status` to compose
      # the anchor for `##`/`###` macros.
      def self.build_cache(identifiers, context = {})
        scope = WorkPackage.where_display_id_in(*identifiers)
        scope = if context[:static_html]
                  scope.includes(:type, :status)
                else
                  scope.select(:id, :identifier)
                end
        work_packages = scope.to_a
        all_wp_ids = work_packages.map(&:id)
        visible_ids = WorkPackage.visible.where(id: all_wp_ids).pluck(:id).to_set
        lookup = index_by_id_and_identifier(work_packages)
        fold_in_alias_keys(lookup, identifiers, all_wp_ids:)
        WorkPackagePreloadCache.new(lookup:, visible_ids:)
      end
      private_class_method :build_cache

      # Keys are stringified at write time so callers can read with a single
      # `identifier.to_s` regardless of whether the input is a numeric id or
      # a semantic identifier.
      def self.index_by_id_and_identifier(work_packages)
        work_packages.each_with_object({}) do |wp, lookup|
          lookup[wp.id.to_s] = wp
          lookup[wp.identifier.to_s] = wp if wp.identifier.present?
        end
      end
      private_class_method :index_by_id_and_identifier

      def self.fold_in_alias_keys(lookup, identifiers, all_wp_ids:)
        unmapped = identifiers.map(&:to_s) - lookup.keys
        return if unmapped.empty? || all_wp_ids.empty?

        WorkPackageSemanticAlias
          .where(work_package_id: all_wp_ids, identifier: unmapped)
          .pluck(:identifier, :work_package_id)
          .each { |ident, wp_id| lookup[ident] = lookup[wp_id.to_s] }
      end
      private_class_method :fold_in_alias_keys

      # Flattens the three alternation branches into a single `:sep` /
      # `:identifier` shape so callers don't branch on which one matched.
      def self.parse_match(match)
        {
          leading: match[:leading],
          escaped: match[:escaped],
          project_prefix: match[:project_prefix],
          project_identifier: match[:project_identifier],
          prefix: match[:prefix],
          sep: match[:hash_sep] || match[:rev_sep] || match[:colon_sep],
          raw_identifier: match[:hash_id] || match[:rev_id] || match[:colon_value],
          identifier: match[:hash_id] || match[:rev_id] || match[:quoted] || match[:colon_value]
        }
      end

      def self.process_match(matchdata, matched_string, context)
        instance = new(matched_string:, context:, **parse_match(matchdata))
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

      def initialize(matched_string:,
                     leading:,
                     escaped:,
                     project_prefix:,
                     project_identifier:,
                     prefix:,
                     sep:,
                     raw_identifier:,
                     identifier:,
                     context:)
        super()
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
          handler = klazz.new(self, context:)

          if handler.applicable?
            @link = handler.call
            break
          end
        end
      rescue StandardError => e
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
