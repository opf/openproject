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

# Captures the user guide screenshots into docs/user-guide. These specs only run on demand:
# DOCS_SCREENSHOTS=1 bundle exec rspec spec/features/docs_screenshots
module DocsScreenshots
  FROZEN_AT = Time.utc(2026, 10, 14, 9)
  WINDOW_SIZE = [1280, 800].freeze
  SCALE = 1.25
  STILL_PAGE_CSS = <<~CSS
    *, *::before, *::after { animation: none !important; transition: none !important; caret-color: transparent !important; }
  CSS

  # Content containers stretch to the viewport height, so `crop:` ends the capture below the
  # lowest visible text or graphic, open menus included.
  CONTENT_AREA_JS = <<~JS
    const element = document.querySelector(arguments[0]);
    const { x, y, width } = element.getBoundingClientRect();
    const leaves = [...element.querySelectorAll("*")]
      .filter((child) => child.childElementCount === 0 && child.checkVisibility({ visibilityProperty: true }))
      .filter((leaf) => leaf.textContent.trim() !== "" || leaf.matches("img, svg *, input, textarea, select"));
    const bottom = Math.max(...leaves.map((leaf) => leaf.getBoundingClientRect().bottom));
    return { x, y, width, height: Math.min(bottom + 16, window.innerHeight) - y };
  JS

  # Relative dates are rendered by the browser, so its clock is shifted to the frozen server time.
  # It keeps ticking from there, as timers and debounced callbacks rely on it.
  BROWSER_CLOCK_JS = <<~JS.freeze
    (() => {
      const RealDate = Date;
      const offset = #{FROZEN_AT.to_i * 1000} - RealDate.now();
      globalThis.Date = class extends RealDate {
        constructor(...args) { super(...(args.length ? args : [RealDate.now() + offset])); }
        static now() { return RealDate.now() + offset; }
      };
    })();
  JS

  # The headless browser has no pointer and ignores emulating one, so it styles the page as a touch
  # screen. The rules meant for a mouse are appended unconditionally instead, reading stylesheets
  # served from another origin, like the frontend dev server's, from their source.
  UNREADABLE_SHEETS_JS = <<~JS
    [...document.styleSheets]
      .filter((sheet) => { try { sheet.cssRules; return false; } catch { return true; } })
      .map((sheet) => sheet.href)
  JS
  MOUSE_RULES_JS = <<~'JS'
    const mouse = /\((any-)?(hover: *hover|pointer: *fine)\)/;
    const collect = (container) => [...container.cssRules].flatMap((rule) => {
      if (rule instanceof CSSMediaRule && mouse.test(rule.conditionText)) return [...rule.cssRules].map((inner) => inner.cssText);
      return rule.cssRules ? collect(rule) : [];
    });
    const readable = [...document.styleSheets].filter((sheet) => { try { return sheet.cssRules; } catch { return false; } });
    const parsed = arguments[0].map((text) => { const sheet = new CSSStyleSheet(); sheet.replaceSync(text); return sheet; });
    const style = document.createElement("style");
    style.textContent = [...readable, ...parsed].flatMap(collect).join("\n");
    document.head.append(style);
  JS

  def self.stylesheet_source(href)
    (@stylesheet_sources ||= {})[href] ||= Net::HTTP.get(URI(href))
  end

  def docs_screenshot(name, crop: nil)
    expect(page).to have_css(".top-menu-search")
    page.driver.wait_for_network_idle
    page.execute_script(<<~JS, STILL_PAGE_CSS)
      document.head.insertAdjacentHTML("beforeend", `<style>${arguments[0]}</style>`)
    JS
    page.execute_script(MOUSE_RULES_JS, page.evaluate_script(UNREADABLE_SHEETS_JS).map { DocsScreenshots.stylesheet_source(it) })

    area = page.evaluate_script("(function() { #{CONTENT_AREA_JS} }).apply(null, arguments)", crop) if crop
    page.driver.browser.screenshot(path: Rails.root.join("docs/user-guide/#{name}.png").to_s, area:, scale: SCALE)
  end
end

RSpec.configure do |config|
  config.filter_run_excluding :docs_screenshots if ENV["DOCS_SCREENSHOTS"].blank?
  config.include DocsScreenshots, :docs_screenshots
  config.around(:each, :docs_screenshots) { |example| travel_to(DocsScreenshots::FROZEN_AT) { example.run } }
  config.before(:each, :docs_screenshots) do
    page.current_window.resize_to(*DocsScreenshots::WINDOW_SIZE)
    page.driver.browser.page.command("Page.addScriptToEvaluateOnNewDocument", source: DocsScreenshots::BROWSER_CLOCK_JS)
  end
end
