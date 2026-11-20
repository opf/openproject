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
require_relative "shared/shared_call_examples"
require_relative "shared/shared_setup_context"

RSpec.describe Settings::UpdateService do
  include_context "with update service setup"

  describe "#call" do
    subject { instance.call(params) }

    include_examples "successful call"

    context "when the contract is not successfully validated" do
      let(:contract_success) { false }

      include_examples "unsuccessful call"
    end

    context "when a non-secret setting receives the secret placeholder" do
      let(:new_setting_value) { Settings::Definition::SECRET_PLACEHOLDER }

      include_examples "successful call"
    end

    context "with a secret setting" do
      let(:setting_definition) { instance_double(Settings::Definition, secret?: true) }

      context "when the secret placeholder is submitted" do
        let(:new_setting_value) { Settings::Definition::SECRET_PLACEHOLDER }

        it "is successful" do
          expect(subject).to be_success
        end

        it "keeps the stored value" do
          subject

          expect(Setting).not_to have_received(:[]=)
        end
      end

      context "when a new value is submitted" do
        include_examples "successful call"
      end

      context "when an empty value is submitted" do
        let(:new_setting_value) { "" }

        include_examples "successful call"
      end
    end
  end
end
