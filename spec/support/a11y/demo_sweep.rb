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

require "uri"
require "json"
require "fileutils"

module A11y
  module DemoSweep
    KNOWN_VIOLATIONS = [].freeze

    class LinkPolicy
      ACTIONS = %w[index show edit].freeze
      UNSAFE = %r{(?:\A|[/_.-])(?:logout|signout|delete|destroy|export|download)(?:[/_.-]|\z)}i

      def initialize(origin:, recognize:)
        @origin = URI(origin)
        @recognize = recognize
      end

      def destination(link, from:)
        return unless navigation_link?(link)

        uri = URI.join(@origin.to_s, from, link.fetch("href"))
        return unless safe_uri?(uri)
        return unless ACTIONS.include?(route(uri.path)[:action])

        uri.path.empty? ? "/" : uri.path
      rescue URI::Error, ArgumentError
        nil
      end

      def detail?(path, index:)
        source = route(index)
        target = route(path)
        source[:action] == "index" && %w[show edit].include?(target[:action]) && source[:controller] == target[:controller]
      end

      private

      def navigation_link?(link)
        href = link["href"].to_s
        !href.empty? && !href.start_with?("#") &&
          %w[download data-method data-turbo-method].none? { |attribute| link.key?(attribute) }
      end

      def safe_uri?(uri)
        return false unless uri.is_a?(URI::HTTP) && same_origin?(uri)
        return false if URI.decode_www_form(uri.query.to_s).any? { |key, _| %w[_method format download export].include?(key) }

        path = URI::DEFAULT_PARSER.unescape(uri.path)
        !path.match?(UNSAFE) && File.extname(path).empty?
      end

      def route(path)
        @recognize.call(path).transform_keys(&:to_sym)
      rescue StandardError
        {}
      end

      def same_origin?(uri)
        [uri.scheme, uri.host, uri.port] == [@origin.scheme, @origin.host, @origin.port]
      end
    end

    class Crawler
      def initialize(policy:, result:, visit:, scan:, max_pages: 100)
        raise ArgumentError, "max_pages must be positive" unless max_pages.positive?

        @policy = policy
        @result = result
        @visit = visit
        @scan = scan
        @max_pages = max_pages
      end

      def run(roots)
        queue = roots.sort.uniq.map { |path| [path, 0] }
        seen = []
        @discoveries = {}
        @navigated = []
        @redirects = {}
        @depth_limited_pages = []
        until queue.empty? || seen.size >= @max_pages
          path, depth = queue.shift
          next if seen.include?(path) || @navigated.include?(path)

          seen << path
          enqueue_discoveries(queue, seen, path, depth)
        end
        omitted = queue.map(&:first).uniq - seen - @navigated
        @result.crawl = { max_depth: 2, max_pages: @max_pages, truncated: omitted.any?, omitted_pages: omitted,
                          discoveries: @discoveries, redirects: @redirects,
                          depth_limited_pages: @depth_limited_pages, attempted_pages: seen }
        @result
      end

      private

      def enqueue_discoveries(queue, seen, path, depth)
        discover(path, depth).each { |target| queue << [target, depth + 1] unless seen.include?(target) }
        detail = @discoveries.dig(path, :detail)
        return unless detail
        return if seen.include?(detail)

        queue.unshift([detail, depth + 1])
      end

      def discover(path, depth)
        links = navigate(path)
        return [] unless links

        canonical = links.fetch(:path)
        @redirects[path] = canonical if canonical != path
        return [] if duplicate_destination?(path, canonical)

        @navigated << canonical
        @result.visited(canonical)
        scan(canonical)
        if depth >= 2
          @depth_limited_pages << canonical
          return []
        end

        destinations = eligible(links.fetch(:menu), canonical)
        detail = eligible(links.fetch(:content), canonical).find { |target| @policy.detail?(target, index: canonical) }
        sources = links.fetch(:menu_sources, {}).transform_values { |links| eligible(links, canonical) }
        @discoveries[path] = { page: canonical, menu: destinations.dup, menu_sources: sources, detail: }
        destinations << detail if detail
        destinations.uniq
      end

      def duplicate_destination?(path, canonical)
        return false unless @navigated.include?(canonical)

        discovery = @discoveries.values.find { |entry| entry[:page] == canonical }
        @discoveries[path] = discovery if discovery
        true
      end

      def eligible(links, path)
        links.filter_map { |link| @policy.destination(link, from: path) }.uniq.sort
      end

      def navigate(path)
        links = @visit.call(path)
        canonical = @policy.destination({ "href" => links.fetch(:path, path) }, from: path)
        raise "Unsafe final destination: #{links[:path]}" unless canonical

        links.merge(path: canonical)
      rescue StandardError => e
        @result.error(path, stage: "navigation", exception: e)
        nil
      end

      def scan(path)
        @result.add(path, @scan.call(path))
      rescue StandardError => e
        @result.error(path, stage: "scan", exception: e)
      end
    end

    class Result
      attr_reader :errors
      attr_accessor :crawl

      def initialize(registry: KNOWN_VIOLATIONS)
        registry.each do |entry|
          unless entry[:page].is_a?(Regexp) && entry[:rule].is_a?(String) && !entry[:rule].strip.empty? &&
                 entry[:reason].is_a?(String) && !entry[:reason].strip.empty?
            raise ArgumentError, "Registry entries need a page pattern, exact rule ID and reason"
          end
        end
        @registry = registry
        @rules = {}
        @visited_pages = []
        @scanned_pages = []
        @errors = []
        @crawl = {}
      end

      def visited(path)
        @visited_pages |= [path]
      end

      def add(path, violations)
        visited(path)
        @scanned_pages |= [path]
        violations.each do |violation|
          rule = @rules[violation.fetch("id")] ||= { help: violation["help"], impact: violation["impact"], findings: [] }
          violation.fetch("nodes").each { |node| add_node(path, violation.fetch("id"), rule, node.fetch("target")) }
        end
      end

      def error(path, stage:, exception:)
        @errors << { page: path, stage:, message: exception.message, exception: exception.class.name }
      end

      def unknown_findings
        occurrences.select { |occurrence| occurrence[:reason].nil? }
      end

      def known_reasons
        occurrences.filter_map { |occurrence| occurrence[:reason] }.uniq
      end

      def status
        return :failed if errors.any? || unknown_findings.any?
        return :pending if known_reasons.any?

        :passed
      end

      def to_h
        rules = @rules.sort.to_h.transform_values { |rule| rule.merge(pages: pages_for(rule)) }
        { status:, visited_pages: @visited_pages, scanned_pages: @scanned_pages, errors:, crawl:, rules: }
      end

      def write(directory)
        FileUtils.mkdir_p(directory)
        File.write(File.join(directory, "report.json"), JSON.pretty_generate(to_h))
        File.write(File.join(directory, "report.md"), markdown)
      end

      private

      def add_node(path, id, rule, selector)
        normalized = normalize_selector(selector)
        finding = rule[:findings].find { |entry| entry[:normalized_selector] == normalized }
        unless finding
          finding = { normalized_selector: normalized, pages: {} }
          rule[:findings] << finding
        end
        reason = @registry.find { |entry| entry[:rule] == id && entry[:page].match?(path) }&.fetch(:reason)
        occurrence = finding[:pages][path] ||= { reason:, selectors: [] }
        occurrence[:selectors] |= [selector]
      end

      def normalize_selector(selector)
        selector.map do |part|
          part.is_a?(Array) ? normalize_selector(part) : part.gsub(%r{(?<=[_/-])\d+|(?<=#)\d+}, ":id")
        end
      end

      def occurrences
        @rules.values.flat_map { |rule| rule[:findings].flat_map { |finding| finding[:pages].values } }
      end

      def pages_for(rule)
        rule[:findings].each_with_object({}) do |finding, pages|
          finding[:pages].each do |path, occurrence|
            (pages[path] ||= []) << occurrence.merge(normalized_selector: finding[:normalized_selector])
          end
        end.sort.to_h
      end

      def markdown
        lines = ["# Demo page axe audit", "", "Status: #{status}", "", "## Crawl", "", "```json",
                 JSON.pretty_generate(crawl), "```", "", "## Visited pages", ""]
        lines.concat(@visited_pages.map { |path| "- `#{path}`" })
        lines.push("", "Successfully scanned pages: #{@scanned_pages.size}", "")
        @rules.sort.each do |id, rule|
          lines.push("", "## #{id}: #{rule[:help]}", "", "Impact: #{rule[:impact]}")
          pages_for(rule).each do |path, findings|
            lines.push("", "### #{path}")
            findings.each do |finding|
              lines.push("", "Reason: #{finding[:reason] || 'UNKNOWN'}", "",
                         "Normalized selector: `#{JSON.generate(finding[:normalized_selector])}`", "",
                         "Original selectors: `#{JSON.generate(finding[:selectors])}`")
            end
          end
        end
        lines.push("", "## Errors", "", "```json", JSON.pretty_generate(errors), "```", "")
        lines.join("\n")
      end
    end
  end
end
