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
require_module_spec_helper

RSpec.describe ITSM::InboundEmails::WorkPackageAttributes do
  subject(:attributes) { described_class.new(ITSM::InboundEmail.new(raw)).to_h }

  let(:email_subject) { "Printer broken" }
  let(:body) { "The printer on floor 2 is broken." }
  let(:raw) { Mail.new(from: "jane@customer.example", subject: email_subject, body:).to_s }

  it "takes the subject, the text as a code block and the sender as the cause" do
    expect(attributes).to eq(subject: "Printer broken",
                             description: "```\nThe printer on floor 2 is broken.\n```",
                             journal_cause: Journal::CausedByEmail.new(sender_address: "jane@customer.example"))
  end

  context "without a subject" do
    let(:email_subject) { nil }

    it "uses a placeholder" do
      expect(attributes[:subject]).to eq("(no subject)")
    end

    context "with another default language", with_settings: { default_language: "de" } do
      before { allow(I18n).to receive(:t).and_call_original }

      it "uses the placeholder in that language" do
        attributes

        expect(I18n).to have_received(:t).with(:label_email_without_subject, locale: "de")
      end
    end
  end

  context "with a subject longer than a work package allows" do
    let(:email_subject) { "Printer broken " * 30 }

    it "shortens it" do
      expect(attributes[:subject].length).to eq(255)
    end
  end

  context "with backticks in the text" do
    let(:body) { "Please run ```lpstat``` again" }

    it "uses a fence the text cannot close" do
      expect(attributes[:description]).to eq("````\nPlease run ```lpstat``` again\n````")
    end
  end

  context "with text that would otherwise be formatted" do
    let(:work_package) { create(:work_package) }
    let(:body) { "See ##{work_package.id}, **this** and <b>that</b> {{toc}}" }

    it "shows it as written" do
      rendered = OpenProject::TextFormatting::Renderer.format_text(attributes[:description])

      expect(rendered).to include("See ##{work_package.id}, **this** and &lt;b&gt;that&lt;/b&gt; {{toc}}")
      expect(rendered).not_to include("<a ", "<strong>", "<b>")
    end
  end

  context "without text" do
    let(:body) { "" }

    it "has no description" do
      expect(attributes[:description]).to be_nil
    end
  end
end
