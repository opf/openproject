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
  subject(:delivery) { described_class.new(address: "203.0.113.10", port: 465, tls: true) }

  let(:context) { OpenSSL::SSL::SSLContext.new }

  before do
    allow(Net::SMTP).to receive(:default_ssl_context).and_return(context)
    allow(context).to receive(:min_version=).and_call_original
  end

  it "requires TLS 1.2 or newer" do
    delivery.send(:build_smtp_session)

    expect(context).to have_received(:min_version=).with(OpenSSL::SSL::TLS1_2_VERSION)
  end
end
