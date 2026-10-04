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

RSpec.describe Documents::OAuth::EnsureApplicationService do
  subject(:service_call) { described_class.new.call }

  describe "#call" do
    context "when the OAuth application does not exist" do
      it "creates a new application" do
        expect { service_call }.to change(Doorkeeper::Application, :count).by(1)
      end

      it "returns a successful service result" do
        result = service_call
        expect(result).to be_success
      end

      it "creates an application with the correct attributes" do
        result = service_call
        application = result.result

        expect(application.uid).to eq(described_class::APPLICATION_UID)
      end
    end

    context "when the OAuth application already exists" do
      let!(:existing_application) do
        create(:oauth_application, uid: described_class::APPLICATION_UID)
      end

      it "does not create a new application" do
        expect { service_call }.not_to change(Doorkeeper::Application, :count)
      end

      it "returns a successful service result with the existing application" do
        result = service_call
        expect(result).to be_success
        expect(result.result).to eq(existing_application)
      end
    end
  end
end
