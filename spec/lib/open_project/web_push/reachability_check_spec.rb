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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe OpenProject::WebPush::ReachabilityCheck do
  subject(:results) { described_class.call }

  let(:response) { instance_double(Net::HTTPOK, code: "200") }

  before { allow(OpenProject::SsrfProtection).to receive(:head).and_return(response) }

  it "returns one result per probed host in order" do
    expect(results.map(&:host)).to eq(described_class.hosts)
  end

  it "probes the host itself, except where only a sample subdomain answers" do
    results

    expect(OpenProject::SsrfProtection).to have_received(:head).with("https://fcm.googleapis.com/", any_args)
    expect(OpenProject::SsrfProtection).to have_received(:head).with("https://web.push.apple.com/", any_args)
    expect(OpenProject::SsrfProtection).not_to have_received(:head).with("https://push.apple.com/", any_args)
  end

  it "reports an HTTP response as reachable with its status code and no reason" do
    expect(results).to all(have_attributes(reachable?: true, code: "200", reason: nil))
  end

  context "with an error status" do
    let(:response) { instance_double(Net::HTTPNotFound, code: "404") }

    it "is still reachable" do
      expect(results.first).to have_attributes(reachable?: true, code: "404")
    end
  end

  context "with a redirect response" do
    let(:response) { instance_double(Net::HTTPFound, code: "302") }

    it "is reachable" do
      expect(results).to all(have_attributes(reachable?: true, code: "302"))
    end
  end

  {
    Net::OpenTimeout.new => :timeout,
    Net::ReadTimeout.new => :timeout,
    SsrfFilter::UnresolvedHostname.new("x") => :unresolved,
    SsrfFilter::PrivateIPAddress.new("x") => :private_address,
    SsrfFilter::TooManyRedirects.new("x") => :filtered,
    OpenSSL::SSL::SSLError.new => :tls,
    Errno::ECONNREFUSED.new => :connection,
    SocketError.new => :connection,
    EOFError.new => :connection,
    IOError.new => :connection,
    Net::HTTPBadResponse.new => :connection
  }.each do |error, reason|
    context "when the request raises #{error.class}" do
      before { allow(OpenProject::SsrfProtection).to receive(:head).and_raise(error) }

      it "is unreachable with the #{reason} reason and does not raise" do
        expect(results.first).to have_attributes(reachable?: false, reason:, code: nil)
      end
    end
  end

  context "when only the Apple probe raises" do
    before do
      allow(OpenProject::SsrfProtection).to receive(:head) do |url, **|
        raise Net::OpenTimeout if url == "https://web.push.apple.com/"

        response
      end
    end

    it "leaves the other probes reachable" do
      expect(results.to_h { [it.host, it.reachable?] })
        .to eq("fcm.googleapis.com" => true,
               "updates.push.services.mozilla.com" => true,
               "web.push.apple.com" => false)
    end
  end

  context "with a stored subscription endpoint on a sample host" do
    before { create(:push_subscription, endpoint: "https://web.push.apple.com/abc") }

    it "probes it once" do
      expect(results.map(&:host)).to eq(%w[fcm.googleapis.com updates.push.services.mozilla.com web.push.apple.com])
    end

    it "reports it as unresolved rather than inconclusive when it does not resolve" do
      allow(OpenProject::SsrfProtection).to receive(:head).and_raise(SsrfFilter::UnresolvedHostname.new("x"))

      expect(results.find { it.host == "web.push.apple.com" }).to have_attributes(reason: :unresolved)
    end
  end

  context "with subscriptions on two regional Windows push hosts" do
    before do
      create(:push_subscription, endpoint: "https://wns2-db5p.notify.windows.com/w/?token=abc")
      create(:push_subscription, endpoint: "https://wns2-am3p.notify.windows.com/w/?token=def")
    end

    it "probes each of them after the known services" do
      expect(results.map(&:host)).to eq(%w[fcm.googleapis.com
                                           updates.push.services.mozilla.com
                                           web.push.apple.com
                                           wns2-am3p.notify.windows.com
                                           wns2-db5p.notify.windows.com])
    end
  end

  context "with a stored subscription endpoint at an unknown service" do
    before { create(:push_subscription, endpoint: "https://push.example.org/sub/abc") }

    it "probes it after the known services" do
      expect(results.map(&:host)).to eq(%w[fcm.googleapis.com
                                           updates.push.services.mozilla.com
                                           web.push.apple.com
                                           push.example.org])
    end
  end

  context "when a sample host does not resolve" do
    before do
      allow(OpenProject::SsrfProtection).to receive(:head).and_raise(SsrfFilter::UnresolvedHostname.new("x"))
    end

    it "is inconclusive for sample hosts and unresolved for the others" do
      expect(results.to_h { [it.host, it.reason] })
        .to eq("fcm.googleapis.com" => :unresolved,
               "updates.push.services.mozilla.com" => :unresolved,
               "web.push.apple.com" => :sample_unresolved)
    end
  end
end
