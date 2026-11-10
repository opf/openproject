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

RSpec.describe ITSM::InboundEmail do
  subject(:headers) { email.headers }

  let(:email) { described_class.new(raw) }
  let(:raw) do
    Mail.new(
      message_id: "<request-1@customer.example>",
      in_reply_to: "<answer-1@openproject.example>",
      references: "<request-0@customer.example> <answer-1@openproject.example>",
      from: "Jane Requester <jane@customer.example>",
      to: "support@example.com",
      cc: ["colleague@customer.example", "boss@customer.example"],
      subject: "=?UTF-8?Q?Dr=C3=BCcker_kaputt?=",
      body: "The printer is broken."
    ).to_s
  end

  it "reads the headers" do
    expect(headers).to eq(
      described_class::Headers.new(
        message_id: "request-1@customer.example",
        in_reply_to: "answer-1@openproject.example",
        references: %w[request-0@customer.example answer-1@openproject.example],
        from_address: "jane@customer.example",
        from_name: "Jane Requester",
        to_addresses: %w[support@example.com],
        cc_addresses: %w[colleague@customer.example boss@customer.example],
        subject: "Drücker kaputt"
      )
    )
  end

  it "keeps the email content out of inspect" do
    headers

    expect(email.inspect).not_to include("jane@customer.example", "printer")
  end

  context "without optional headers" do
    let(:raw) { "From: jane@customer.example\r\nTo: support@example.com\r\n\r\nHello" }

    it "has no reply information, no CCs and no subject" do
      expect(headers).to have_attributes(in_reply_to: nil, references: [], cc_addresses: [], from_name: nil, subject: nil)
    end

    it "derives a stable message ID from the content" do
      expect(headers.message_id).to eq(described_class.new(raw.dup).headers.message_id)
      expect(headers.message_id).to end_with("@openproject.invalid")
    end
  end

  context "with a sender that is not an email address" do
    let(:raw) { "From: not an address at all\r\nTo: support@example.com\r\n\r\nHello" }

    it "has no sender" do
      expect(headers).to have_attributes(from_address: nil, from_name: nil)
    end
  end

  context "with addresses in mixed case" do
    let(:raw) do
      "From: Jane@Customer.example\r\nTo: Support@Example.com\r\n" \
        "Cc: Colleague@Customer.example, colleague@customer.example\r\n\r\nHello"
    end

    it "normalizes them" do
      expect(headers).to have_attributes(from_address: "jane@customer.example",
                                         to_addresses: %w[support@example.com],
                                         cc_addresses: %w[colleague@customer.example])
    end
  end

  context "with a recipient header that cannot be parsed" do
    let(:raw) do
      "From: jane@customer.example\r\n" \
        "To: \"Broken <support@example\r\n" \
        "Cc: colleague@customer.example, boss@customer.example\r\n\r\nHello"
    end

    it "keeps only the email addresses" do
      expect(headers).to have_attributes(to_addresses: [],
                                         cc_addresses: %w[colleague@customer.example boss@customer.example])
    end
  end

  context "with a recipient that is not valid UTF-8" do
    let(:raw) { "From: jane@customer.example\r\nTo: \xFFsupport@example.com\r\n\r\nHello".b }

    it "replaces the invalid bytes instead of failing" do
      expect(headers.to_addresses).to eq(["�support@example.com"])
    end
  end

  context "with header bytes that are not valid UTF-8" do
    let(:raw) { "From: jane@customer.example\r\nSubject: \xFF\xFEPrinter\r\n\r\nHello".b }

    it "replaces them" do
      expect(headers.subject).to eq("��Printer")
    end
  end

  describe "#text" do
    subject(:text) { email.text }

    it "reads the plain text body" do
      expect(text).to eq("The printer is broken.")
    end

    it "keeps the email content out of inspect" do
      text

      expect(email.inspect).not_to include("printer")
    end

    context "with a charset other than UTF-8" do
      let(:raw) do
        "From: jane@customer.example\r\nContent-Type: text/plain; charset=ISO-8859-1\r\n\r\nDr\xFCcker kaputt".b
      end

      it "converts it to UTF-8" do
        expect(text).to eq("Drücker kaputt")
      end
    end

    context "with Windows line endings and surrounding blank lines" do
      let(:raw) { "From: jane@customer.example\r\n\r\n\r\nFirst line\r\nSecond line\r\n\r\n" }

      it "uses plain line breaks and trims the text" do
        expect(text).to eq("First line\nSecond line")
      end
    end

    context "with bytes that are not valid UTF-8" do
      let(:raw) { "From: jane@customer.example\r\n\r\n\xFF\xFEPrinter".b }

      it "replaces them" do
        expect(text).to eq("��Printer")
      end
    end

    context "with null bytes" do
      let(:raw) { "From: jane@customer.example\r\n\r\nPrinter\u0000 broken" }

      it "removes them, as the database cannot store them" do
        expect(text).to eq("Printer broken")
      end
    end

    context "with a plain text and an HTML version" do
      let(:raw) do
        Mail.new do
          text_part { body "The plain version." }
          html_part do
            content_type "text/html; charset=UTF-8"
            body "<p>The HTML version.</p>"
          end
        end.to_s
      end

      it "prefers the plain text version" do
        expect(text).to eq("The plain version.")
      end
    end

    context "with only an HTML version" do
      let(:raw) do
        "From: jane@customer.example\r\nContent-Type: text/html; charset=UTF-8\r\n\r\n" \
          "<html><head><style>p { color: red }</style></head><body>" \
          "<p>Hello <b>team</b>,</p><p>first line<br>second line</p>" \
          "<p>a &amp; b &lt;c&gt;</p><script>alert('hi')</script>" \
          "</body></html>"
      end

      it "converts it to text with its line breaks" do
        expect(text).to eq("Hello team,\n\nfirst line\nsecond line\n\na & b <c>")
      end
    end

    context "with an attached text file and an HTML body" do
      let(:raw) do
        Mail.new do
          html_part do
            content_type "text/html; charset=UTF-8"
            body "<p>See the attached notes.</p>"
          end
          add_file filename: "notes.txt", content: "Attached notes"
        end.to_s
      end

      it "reads the body, not the attachment" do
        expect(text).to eq("See the attached notes.")
      end
    end

    context "with the body nested in related and mixed parts" do
      let(:plain_version) do
        <<~MIME
          --alternative
          Content-Type: text/plain; charset=UTF-8

          The plain version.
        MIME
      end
      let(:raw) do
        <<~MIME.gsub("\n", "\r\n")
          From: jane@customer.example
          Content-Type: multipart/mixed; boundary="mixed"

          --mixed
          Content-Type: multipart/related; boundary="related"

          --related
          Content-Type: multipart/alternative; boundary="alternative"

          #{plain_version}--alternative
          Content-Type: text/html; charset=UTF-8

          <p>The HTML version.</p><img src="cid:logo">
          --alternative--
          --related
          Content-Type: image/png
          Content-Disposition: inline; filename="logo.png"
          Content-ID: <logo>
          Content-Transfer-Encoding: base64

          iVBORw0KGgo=
          --related--
          --mixed
          Content-Type: text/plain; charset=UTF-8
          Content-Disposition: attachment; filename="notes.txt"

          Attached notes
          --mixed--
        MIME
      end

      it "reads the plain text version" do
        expect(text).to eq("The plain version.")
      end

      context "without a plain text version" do
        let(:plain_version) { "" }

        it "reads the HTML version, not the inline image or the attachment" do
          expect(text).to eq("The HTML version.")
        end
      end
    end

    context "with the text split around an inline image" do
      let(:raw) do
        <<~MIME.gsub("\n", "\r\n")
          From: jane@customer.example
          Content-Type: multipart/mixed; boundary="mixed"

          --mixed
          Content-Type: text/plain; charset=UTF-8

          Before the image.
          --mixed
          Content-Type: image/png
          Content-Disposition: inline; filename="screenshot.png"
          Content-Transfer-Encoding: base64

          iVBORw0KGgo=
          --mixed
          Content-Type: text/plain; charset=UTF-8

          After the image.
          --mixed--
        MIME
      end

      it "reads all parts of the text" do
        expect(text).to eq("Before the image.\n\nAfter the image.")
      end
    end

    context "with only an attachment" do
      let(:raw) do
        Mail.new { add_file filename: "scan.pdf", content: "%PDF-1.7" }.to_s
      end

      it "has no text" do
        expect(text).to eq("")
      end
    end
  end

  describe "#header_value" do
    let(:raw) { "From: jane@customer.example\r\nAuto-Submitted: auto-replied\r\nX-Bad: \xFFvalue\r\n\r\nHello".b }

    it "returns a header's value as valid UTF-8, or nothing" do
      expect(email.header_value("Auto-Submitted")).to eq("auto-replied")
      expect(email.header_value("X-Bad")).to eq("�value")
      expect(email.header_value("Precedence")).to be_nil
    end
  end

  describe "#delivery_addresses" do
    let(:raw) do
      "Delivered-To: <Inbox@mail.example>\r\nX-Original-To: support@company.example\r\n" \
        "Delivered-To: jane@customer.example\r\nFrom: jane@customer.example\r\n\r\nHello"
    end

    it "returns the addresses the mail server delivered the email to last" do
      expect(email.delivery_addresses).to eq(%w[inbox@mail.example support@company.example])
    end

    context "without delivery headers" do
      let(:raw) { "From: jane@customer.example\r\n\r\nHello" }

      it { expect(email.delivery_addresses).to be_empty }
    end
  end

  describe "#delivery_report?" do
    let(:content_type) { "multipart/report; report-type=delivery-status; boundary=report" }
    let(:raw) { "From: mailer-daemon@example.com\r\nContent-Type: #{content_type}\r\n\r\n--report--" }

    it { expect(email).to be_delivery_report }

    context "with another kind of report" do
      let(:content_type) { "multipart/report; report-type=disposition-notification; boundary=report" }

      it { expect(email).not_to be_delivery_report }
    end

    context "with a normal email" do
      let(:raw) { "From: jane@customer.example\r\n\r\nHello" }

      it { expect(email).not_to be_delivery_report }
    end
  end
end
