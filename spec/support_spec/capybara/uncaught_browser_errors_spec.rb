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

RSpec.describe Capybara::UncaughtBrowserErrors do
  def entries(*texts)
    texts.each_with_index.map { |text, index| CupriteCdpLogger::Sink::Entry.new(sequence: index + 1, text:) }
  end

  def incoming(message)
    "    ◀ 0.123 #{message.to_json}"
  end

  def thrown(description, exception_id: 1, text: "Uncaught")
    incoming(
      method: "Runtime.exceptionThrown",
      params: { exceptionDetails: { exceptionId: exception_id, text:, exception: { className: "TypeError", description: } } }
    )
  end

  after { described_class.expected_sequences.clear }

  describe ".extract" do
    it "returns the uncaught exceptions of the incoming CDP messages" do
      records = described_class.extract(entries(
                                          "\n\n▶ 0.100 #{{ method: 'Runtime.evaluate' }.to_json}",
                                          incoming(method: "Runtime.consoleAPICalled", params: { type: "error", args: [] }),
                                          thrown("TypeError: boom\n    at onOpen (main.js:1:2)")
                                        ))

      expect(records).to contain_exactly(
        have_attributes(sequence: 3, exception_id: 1, class_name: "TypeError",
                        message: "TypeError: boom\n    at onOpen (main.js:1:2)")
      )
    end

    it "drops a rejection that Chrome revoked once it was handled" do
      revoked = incoming(method: "Runtime.exceptionRevoked", params: { reason: "Handler added", exceptionId: 4 })
      records = described_class.extract(entries(
                                          thrown("Error: late", exception_id: 4, text: "Uncaught (in promise)"),
                                          thrown("Error: kept", exception_id: 5),
                                          revoked
                                        ))

      expect(records.map(&:message)).to eq(["Error: kept"])
    end

    it "skips known errors of dependencies" do
      records = described_class.extract(entries(
                                          thrown("InvalidStateError: Failed to execute 'showPopover' on 'HTMLElement': " \
                                                 "Invalid to show a popover during another show operation"),
                                          thrown("TypeError: boom")
                                        ))

      expect(records.map(&:message)).to eq(["TypeError: boom"])
    end

    it "reads a message with a lone surrogate" do
      text = thrown("Error: ok").sub("Error: ok", "Error: \\ud800 broken")

      expect(described_class.extract(entries(text)).first.message).to eq("Error: � broken")
    end

    it "skips lines that are not valid JSON" do
      expect(described_class.extract(entries("    ◀ 0.123 {not json"))).to be_empty
    end
  end

  describe ".unexpected" do
    it "leaves out the errors an example expected" do
      records = described_class.extract(entries(thrown("Error: expected"), thrown("Error: stray", exception_id: 2)))
      described_class.expected_sequences << 1

      expect(described_class.unexpected(records).map(&:message)).to eq(["Error: stray"])
    end
  end

  describe ".raise_if_any!" do
    it "does nothing without errors" do
      expect { described_class.raise_if_any!([]) }.not_to raise_error
    end

    it "raises with each distinct message once, counting repeats" do
      records = described_class.extract(entries(thrown("TypeError: boom"), thrown("TypeError: boom", exception_id: 2),
                                                thrown("RangeError: deep", exception_id: 3)))

      expect { described_class.raise_if_any!(records) }
        .to raise_error(described_class::UncaughtError,
                        "3 uncaught JavaScript error(s) in the browser:\n\n2× TypeError: boom\n\nRangeError: deep")
    end
  end
end
