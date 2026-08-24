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
require_module_spec_helper

module Storages
  module Adapters
    RSpec.describe Registry do
      subject(:registry) { described_class }

      describe "error handling" do
        context "when a missing key is requested" do
          it "raises a MissingContract if it was a contract" do
            expect { registry["onedrive.contracts.some_contract"] }.to raise_error Errors::MissingContract
          end

          it "raises an OperationNotSupported if a command or query is not registered" do
            expect { registry["onedrive.commands.conquer"] }.to raise_error Errors::OperationNotSupported
          end

          it "raises an UnknownProvider if the provider is not registered" do
            expect { registry["one_google_box.commands.create_folder"] }.to raise_error Errors::UnknownProvider
          end

          it "raises a ResolverStandardError if the key cannot be resolved" do
            expect { registry["onedrive.graph.rest_api"] }.to raise_error Errors::ResolverStandardError
          end

          it "logs the failure" do
            allow(Rails.logger).to receive(:error).with("Cannot resolve key one_drive.graph.rest_api.")

            expect { registry["onedrive.graph.rest_api"] }.to raise_error Errors::ResolverStandardError
          end
        end
      end
    end
  end
end
