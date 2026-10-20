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

require "rspec_helper"
require "tmpdir"
require_relative "../../support/a11y/demo_sweep"

RSpec.describe A11y::DemoSweep do
  let(:recognize) do
    lambda do |path|
      case path
      when %r{\A/items\z} then { controller: "items", action: "index" }
      when %r{\A/items/\d+\z} then { controller: "items", action: "show" }
      when "/" then { controller: "homescreen", action: "index" }
      when %r{\A/items/\d+/edit\z} then { controller: "items", action: "edit" }
      when "/settings" then { controller: "settings", action: "edit" }
      when "/items/new" then { controller: "items", action: "new" }
      else { controller: "items", action: path.split("/").last }
      end
    end
  end
  let(:policy) { described_class::LinkPolicy.new(origin: "http://example.test", recognize:) }

  describe "link eligibility" do
    it "normalizes same-origin destinations and drops fragments and query variations" do
      expect(policy.destination({ "href" => "http://example.test/items?sort=x#top" }, from: "/"))
        .to eq("/items")
      expect(policy.destination({ "href" => "2" }, from: "/items/1")).to eq("/items/2")
    end

    it "rejects unsafe links before they can be visited" do
      links = ["#top", "https://elsewhere.test/items", "https://example.test/items", "//elsewhere.test/items",
               "mailto:a@b.test", "/logout", "/items/delete", "/items/destroy", "/items/export", "/items/new",
               "/items/1.pdf", "/items?format=csv", "/items?_method=delete", "/items?download=true"]
      links.each do |href|
        expect(policy.destination({ "href" => href }, from: "/")).to be_nil, href
      end
      ["download", "data-method", "data-turbo-method"].each do |attribute|
        expect(policy.destination({ "href" => "/items", attribute => "" }, from: "/")).to be_nil
      end
    end

    it "recognizes a matching edit detail when a resource has no show page" do
      expect(policy.detail?("/items/1/edit", index: "/items")).to be true
    end

    it "permits menu edit pages and fails closed for unrecognized routes" do
      expect(policy.destination({ "href" => "/settings" }, from: "/")).to eq("/settings")
      expect(policy.detail?("/settings", index: "/items")).to be false
      broken = described_class::LinkPolicy.new(origin: "http://example.test", recognize: ->(_) { raise "no route" })
      expect(broken.destination({ "href" => "/items" }, from: "/")).to be_nil
    end
  end

  describe "bounded discovery" do
    let(:result) { described_class::Result.new }
    let(:graph) do
      { "/" => { menu: ["/items", "/settings"], content: ["/items/99"] },
        "/items" => { menu: [], content: ["/items/2", "/items/1"] },
        "/settings" => { menu: [], content: ["/items/3"] },
        "/items/1" => { menu: ["/items/4"], content: ["/items/5"] } }
    end
    let(:visited) { [] }
    let(:browser) do
      lambda do |path|
        visited << path
        graph.fetch(path).transform_values { |paths| paths.map { |href| { "href" => href } } }
      end
    end

    def crawl(cap: 100, scan: ->(_) { [] })
      described_class::Crawler.new(policy:, result:, visit: browser, scan:, max_pages: cap).run(["/"])
    end

    it "visits one deterministic detail immediately after each index, stopping at depth two" do
      crawl
      expect(visited).to eq(["/", "/items", "/items/1", "/settings"])
      expect(result.to_h[:crawl]).to include(max_depth: 2, max_pages: 100, truncated: false)
      expect(result.crawl[:discoveries]["/items"][:detail]).to eq("/items/1")
      expect(result.crawl[:depth_limited_pages]).to eq(["/items/1"])
    end

    it "retains partial results and visits remaining pages after a navigation failure" do
      failing_browser = lambda do |path|
        raise "cannot navigate" if path == "/items"

        browser.call(path)
      end
      described_class::Crawler.new(policy:, result:, visit: failing_browser, scan: ->(_) { [] }).run(["/"])
      expect(result.errors).to include(hash_including(page: "/items", stage: "navigation"))
      expect(result.to_h[:visited_pages]).to eq(["/", "/settings"])
      expect(result.status).to eq(:failed)
    end

    it "deduplicates safe canonical redirects and discovers details from the final index" do
      visits = []
      scans = []
      redirecting_browser = lambda do |path|
        visits << path
        if path == "/items/1"
          { path:, menu: [], content: [] }
        else
          { path: "/items", menu: [], content: [{ "href" => "/items/1" }] }
        end
      end
      described_class::Crawler.new(policy:, result:, visit: redirecting_browser,
                                   scan: lambda { |path|
                                     scans << path
                                     []
                                   }).run(["/alias-one", "/alias-two"])
      expect(scans).to eq(["/items", "/items/1"])
      expect(visits).to eq(["/alias-one", "/items/1", "/alias-two"])
      expect(result.crawl[:redirects]).to eq("/alias-one" => "/items", "/alias-two" => "/items")
      expect(result.crawl[:discoveries]["/alias-one"][:detail]).to eq("/items/1")
      expect(result.crawl[:discoveries]["/alias-two"]).to eq(result.crawl[:discoveries]["/alias-one"])
    end

    it "rejects external or unsafe final redirect destinations as navigation errors" do
      ["https://external.test/items", "/logout", "/items/new"].each do |target|
        rejected = described_class::Result.new
        described_class::Crawler.new(policy:, result: rejected,
                                     visit: ->(_) { { path: target, menu: [], content: [] } },
                                     scan: ->(_) { raise "must not scan" }).run(["/"])
        expect(rejected.errors).to include(hash_including(stage: "navigation", message: /Unsafe final destination/))
        expect(rejected.to_h[:scanned_pages]).to be_empty
      end
    end

    it "retains eligible menu destinations by source for coverage checks" do
      scoped_browser = lambda do |path|
        browser.call(path).merge(menu_sources: { sidebar: [{ "href" => "/items" }, { "href" => "/logout" }] })
      end
      described_class::Crawler.new(policy:, result:, visit: scoped_browser, scan: ->(_) { [] }).run(["/"])
      expect(result.crawl[:discoveries]["/"][:menu_sources]).to eq(sidebar: ["/items"])
    end

    it "enforces the cap and reports omitted pages" do
      crawl(cap: 2)
      expect(visited).to eq(["/", "/items"])
      expect(result.to_h[:crawl]).to include(truncated: true)
      expect(result.to_h[:crawl][:omitted_pages]).to include("/settings", "/items/1")
    end

    it "keeps previous findings and continues after scan or navigation errors" do
      crawl(scan: ->(path) {
        raise "axe unavailable" if path == "/items"

        []
      })
      expect(result.errors).to include(hash_including(page: "/items", stage: "scan", message: "axe unavailable"))
      expect(result.to_h[:visited_pages]).to include("/items", "/settings", "/items/1")
      expect(result.to_h[:scanned_pages]).not_to include("/items")
      expect(result.crawl[:attempted_pages]).to eq(visited)
      expect(result.status).to eq(:failed)
    end
  end

  describe "results and reports" do
    let(:registry) { [{ page: %r{\A/items/\d+\z}, rule: "label", reason: "SE-712 tracked label" }] }
    let(:result) { described_class::Result.new(registry:) }
    let(:violation) do
      { "id" => "label", "help" => "Inputs need labels", "impact" => "serious",
        "nodes" => [{ "target" => ["#item_123 input:nth-child(2)"] }] }
    end

    it "requires a page pattern, exact rule and a nonempty reason" do
      expect { described_class::Result.new(registry: [{ page: /items/, rule: "label", reason: " " }]) }
        .to raise_error(ArgumentError)
      expect { described_class::Result.new(registry: [{ rule: "label", reason: "tracked" }]) }
        .to raise_error(ArgumentError)
      result.add("/items/1", [violation])
      expect(result.status).to eq(:pending)
      expect(result.known_reasons).to eq(["SE-712 tracked label"])
      result.add("/items", [violation])
      expect(result.status).to eq(:failed)
      expect(result.unknown_findings.size).to eq(1)
    end

    it "collapses numeric selectors while preserving original selectors and page occurrences" do
      result.add("/items/1", [violation])
      other = Marshal.load(Marshal.dump(violation))
      other["nodes"][0]["target"] = ["#item_456 input:nth-child(2)"]
      result.add("/items/2", [other])
      findings = result.to_h[:rules].fetch("label")[:findings]
      expect(findings.size).to eq(1)
      expect(findings.first[:normalized_selector]).to eq(["#item_:id input:nth-child(2)"])
      expect(findings.first[:pages].keys).to eq(["/items/1", "/items/2"])
      expect(findings.first[:pages]["/items/2"][:selectors]).to eq([["#item_456 input:nth-child(2)"]])
    end

    it "writes JSON and Markdown with rule, page, selector, reason, errors and crawl metadata" do
      require "tmpdir"
      result.add("/items/1", [violation])
      result.error("/items/2", stage: "navigation", exception: RuntimeError.new("unreachable"))
      Dir.mktmpdir do |directory|
        result.write(directory)
        report = JSON.parse(File.read(File.join(directory, "report.json")))
        expect(report).to include("rules", "visited_pages", "errors", "crawl")
        markdown = File.read(File.join(directory, "report.md"))
        ["label", "/items/1", "Inputs need labels", "serious", "#item_123", "SE-712 tracked label", "unreachable"].each do |text|
          expect(markdown).to include(text)
        end
      end
      expect(result.status).to eq(:failed)
    end

    it "groups multiple selectors under a single rule/page heading" do
      additional = Marshal.load(Marshal.dump(violation))
      additional["nodes"][0]["target"] = ["#other_234"]
      result.add("/items/1", [violation, additional])
      expect(result.to_h[:rules]["label"][:pages]["/items/1"].size).to eq(2)
      Dir.mktmpdir do |directory|
        result.write(directory)
        expect(File.read(File.join(directory, "report.md")).scan("### /items/1").size).to eq(1)
      end
    end

    it "normalizes record IDs in selector URL attributes without collapsing positional selectors" do
      violation["nodes"][0]["target"] = ['a[data-hover-card-url="/users/4/hover_card"]:nth-child(2)']
      result.add("/items/1", [violation])
      finding = result.to_h[:rules]["label"][:findings].first
      expect(finding[:normalized_selector]).to eq(['a[data-hover-card-url="/users/:id/hover_card"]:nth-child(2)'])
    end

    it "does not exempt a different rule on a registered page" do
      result.add("/items/1", [violation.merge("id" => "color-contrast")])
      expect(result.status).to eq(:failed)
    end

    it "passes a clean completed audit" do
      result.add("/items", [])
      expect(result.status).to eq(:passed)
    end
  end
end
