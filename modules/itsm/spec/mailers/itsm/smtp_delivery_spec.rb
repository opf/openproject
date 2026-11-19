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

RSpec.describe ITSM::SmtpDelivery do
  subject(:delivery) { described_class.new(addresses:, port: 465, tls: true) }

  let(:addresses) { %w[203.0.113.10 203.0.113.11] }
  let(:context) { OpenSSL::SSL::SSLContext.new }

  before do
    allow(Net::SMTP).to receive(:default_ssl_context).and_return(context)
    allow(context).to receive(:min_version=).and_call_original
  end

  it "requires TLS 1.2 or newer" do
    delivery.send(:build_smtp_session)

    expect(context).to have_received(:min_version=).with(OpenSSL::SSL::TLS1_2_VERSION)
  end

  describe "#deliver!" do
    let(:refusing) { [] }
    let(:connected) { [] }

    before do
      allow(Net::SMTP).to receive(:new) do |address, _port|
        instance_double(Net::SMTP, disable_starttls: nil, enable_tls: nil, "open_timeout=": nil, "read_timeout=": nil)
          .tap do |smtp|
            if refusing.include?(address)
              allow(smtp).to receive(:start).and_raise(Errno::ECONNREFUSED)
            else
              allow(smtp).to receive(:start) { connected << address }
            end
          end
      end
    end

    it "sends through the first address" do
      delivery.deliver!(Mail.new)

      expect(connected).to eq(["203.0.113.10"])
    end

    context "when the first address refuses the connection" do
      let(:refusing) { ["203.0.113.10"] }

      it "sends through the next one" do
        delivery.deliver!(Mail.new)

        expect(connected).to eq(["203.0.113.11"])
      end
    end

    context "with the default headers of every email" do
      let(:mail) { Mail.new.tap { Interceptors::DefaultHeaders.delivering_email(it) } }

      it "keeps them" do
        delivery.deliver!(mail)

        expect(mail["Auto-Submitted"].value).to eq("auto-generated")
        expect(mail["Precedence"].value).to eq("bulk")
      end
    end

    context "with an email marked as not automatic" do
      let(:mail) { Mail.new("Auto-Submitted" => "no").tap { Interceptors::DefaultHeaders.delivering_email(it) } }

      it "sends it without the default headers that mark it automatic" do
        delivery.deliver!(mail)

        expect(mail.header.fields.select { it.name == "Auto-Submitted" }.map(&:value)).to eq(["no"])
        expect(mail["Precedence"]).to be_nil
        expect(mail["X-Mailer"].value).to eq("OpenProject")
      end
    end

    context "when every address refuses the connection" do
      let(:refusing) { addresses }

      it "raises the last error" do
        expect { delivery.deliver!(Mail.new) }.to raise_error(Errno::ECONNREFUSED)
        expect(connected).to be_empty
      end
    end
  end
end
