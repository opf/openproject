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

require "spec_helper"

RSpec.describe "Seeded demo pages accessibility", :axe_sweep, :js, :selenium,
               with_config: { edition: "standard" } do
  let(:root_seeder) { RootSeeder.new }
  let(:result) { A11y::DemoSweep::Result.new }
  let(:report_directory) { Rails.root.join("tmp/axe-audit") }

  before do
    root_seeder.seed!
    login_as(root_seeder.admin_user)
  end

  it "audits menu destinations and one detail per index as the seeded admin" do
    visit root_path
    policy = A11y::DemoSweep::LinkPolicy.new(
      origin: page.current_url,
      recognize: ->(path) { Rails.application.routes.recognize_path(path, method: :get) }
    )
    roots = [root_path, admin_index_path] + Project.order(:id).map { |project| project_path(project) }
    crawler = A11y::DemoSweep::Crawler.new(
      policy:, result:, visit: method(:visit_audit_page), scan: method(:scan_audit_page),
      max_pages: Integer(ENV.fetch("AXE_SWEEP_MAX_PAGES", "100"))
    )
    begin
      crawler.run(roots)
      verify_discovery(roots) unless result.crawl[:truncated]
    ensure
      result.write(report_directory)
    end

    expect(result.errors).to be_empty, "Navigation/scan errors: see #{report_directory}/report.md"
    expect(result.unknown_findings).to be_empty, "Unregistered axe violations: see #{report_directory}/report.md"
    skip("Registered axe violations: #{result.known_reasons.join('; ')}") if result.status == :pending
  end

  def verify_discovery(roots)
    discoveries = result.crawl.fetch(:discoveries)
    roots.each { |root| verify_menu_discovery(root, project: roots.drop(2).include?(root)) }
    redirects = result.crawl.fetch(:redirects)
    details = discoveries.values.filter_map { |discovery| discovery[:detail] }
                         .map { |path| redirects.fetch(path, path) }
    unless details.intersect?(result.to_h[:scanned_pages])
      result.error(root_path, stage: "discovery", exception: RuntimeError.new("No seeded detail pages were scanned"))
    end
  end

  def verify_menu_discovery(root, project:)
    discovery = result.crawl.fetch(:discoveries).fetch(root, {})
    source = root == root_path ? :header : :sidebar
    destinations = discovery.dig(:menu_sources, source) || []
    if project
      canonical_root = discovery.fetch(:page, root)
      destinations = destinations.select { |path| path.start_with?("#{canonical_root}/") }
    end
    return if destinations.any?

    result.error(root, stage: "discovery", exception: RuntimeError.new("No eligible #{source} menu links discovered"))
  end

  def visit_audit_page(path)
    visit path
    page.assert_selector("#content")
    page.assert_selector("body.__ng2-bootstrap-has-run", wait: 20)
    page.assert_no_selector(".op-loading-indicator")
    page.document.synchronize do
      raise Capybara::ElementNotFound, "Document is loading" unless page.evaluate_script("document.readyState") == "complete"
    end
    sources = { header: audit_links("header a[href]", visible: :all),
                sidebar: audit_links("#main-menu a[href]", visible: :all) }
    {
      path: page.current_url,
      menu: sources.values.flatten,
      menu_sources: sources,
      content: audit_links("#content a[href]", visible: true)
    }
  end

  def audit_links(selector, visible:)
    link_attributes = %w[href download data-method data-turbo-method]
    page.all(selector, visible:).map do |link|
      link_attributes.each_with_object({}) do |attribute, attributes|
        value = link.native.dom_attribute(attribute)
        attributes[attribute] = value unless value.nil?
      end
    end
  end

  def scan_audit_page(_path)
    audit = Axe::Core.new(page).call(Axe::API::Run.new)
    JSON.parse(JSON.generate(audit.results.to_h)).fetch("violations")
  end
end
