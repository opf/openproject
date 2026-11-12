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

RSpec.describe FlashMessagesOutputSafetyHelper do
  subject { helper.join_flash_messages(flash_messages) }

  shared_examples "HTML safety" do
    it "returns an HTML-safe string" do
      expect(subject).to be_html_safe
    end
  end

  context "when flash_messages is a non-empty Array" do
    let(:flash_messages) { ["Flash message #1", "Flash message #2"] }

    it "joins the two flash messages" do
      expect(subject).to eq "Flash message #1<br />Flash message #2"
    end

    include_examples "HTML safety"
  end

  context "when flash_messages is a nested Array" do
    let(:flash_messages) { ["Flash message #1", ["Flash message #2", "Flash message #3"]] }

    it "joins the three flash messages" do
      expect(subject).to eq "Flash message #1<br />Flash message #2<br />Flash message #3"
    end

    include_examples "HTML safety"
  end

  context "when flash_messages is an empty Array" do
    let(:flash_messages) { [] }

    it "returns an empty String" do
      expect(subject).to eq ""
    end

    include_examples "HTML safety"
  end

  context "when flash_messages is a String" do
    let(:flash_messages) { "Flash message #1" }

    it "returns the String" do
      expect(subject).to eq "Flash message #1"
    end

    include_examples "HTML safety"
  end

  context "when flash_messages is nil" do
    let(:flash_messages) { nil }

    it "returns an empty String" do
      expect(subject).to eq ""
    end

    include_examples "HTML safety"
  end
end
