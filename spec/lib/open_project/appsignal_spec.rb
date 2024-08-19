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
require "appsignal"

RSpec.describe OpenProject::Appsignal do
  describe ".exception_handler" do
    let(:exception) { StandardError.new("I am a fake exception") }

    before do
      allow(Appsignal).to receive(:active?).and_return(true)
      allow(Appsignal).to receive(:send_error)
    end

    it "does nothing if there is no exception in the log context" do
      described_class.exception_handler("message")
      expect(Appsignal).not_to have_received(:send_error)
    end

    it "stores the exception in current appsignal transaction if one is available" do
      transaction = Appsignal::Transaction.create(
        SecureRandom.uuid,
        Appsignal::Transaction::BACKGROUND_JOB,
        Appsignal::Transaction::GenericRequest.new({})
      )
      allow(transaction).to receive(:set_error)
      described_class.exception_handler("message", exception:)

      expect(transaction).to have_received(:set_error).with(exception)
      expect(Appsignal).not_to have_received(:send_error)
    ensure
      Appsignal::Transaction.complete_current!
    end

    it "sends an error through Appsignal if no current appsignal transaction available" do
      allow(Appsignal).to receive(:send_error)
      described_class.exception_handler("message", exception:)

      expect(Appsignal).to have_received(:send_error).with(exception)
    end
  end
end
