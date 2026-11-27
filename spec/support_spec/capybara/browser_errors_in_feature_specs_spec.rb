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

RSpec.describe "Uncaught browser errors in feature specs", :js, type: :feature do
  let(:collector) { Capybara::UncaughtBrowserErrors }

  def throw_later(message)
    page.execute_script("const message = arguments[0]; setTimeout(() => { throw new Error(message) })", message)
  end

  def errors_since(cursor)
    collector.unexpected(collector.extract(CupriteCdpLogger.logger.since(cursor)))
  end

  # A blank page: on application pages, Angular's global listener rewraps errors
  # from scripts Cuprite evaluates as an opaque "Script error.".
  before { visit "about:blank" }

  it "lets an example expect an error the browser throws" do
    expect_browser_errors(/expected boom/) { throw_later("expected boom") }
  end

  it "fails the expectation when the error does not occur" do
    using_wait_time(0.5) do
      expect { expect_browser_errors(/never thrown/) { nil } }
        .to raise_error(RSpec::Expectations::ExpectationNotMetError, %r{did not occur.*/never thrown/}m)
    end
  end

  it "sees errors of named sessions, and of the default session after one opened" do
    expect_browser_errors(/other session boom/) do
      using_session(:other) do
        visit "about:blank"
        throw_later("other session boom")
      end
    end

    expect_browser_errors(/default session boom/) { throw_later("default session boom") }
  end

  it "counts an error outside the block" do
    cursor = CupriteCdpLogger.logger.cursor

    expect_browser_errors(/inside/) { throw_later("inside") }
    throw_later("outside")

    wait_for { errors_since(cursor).map(&:message) }.to include(a_string_including("outside"))
    CupriteCdpLogger.clear
  end

  it "ignores a rejection that is handled later" do
    cursor = CupriteCdpLogger.logger.cursor

    page.execute_script(<<~JS)
      const rejected = Promise.reject(new Error("handled later"));
      setTimeout(() => rejected.catch(() => {}), 50);
    JS

    wait_for { CupriteCdpLogger.logger.since(cursor).map(&:text).join }.to include("Runtime.exceptionRevoked")
    expect(errors_since(cursor)).to be_empty
  end
end
