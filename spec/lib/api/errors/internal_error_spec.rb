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

RSpec.describe API::Errors::InternalError do
  subject { described_class.new(sensitive_message, exception:) }

  let(:sensitive_message) { "This message might contain sensitive information" }
  let(:exception) { nil }
  let(:generic_message) { I18n.t("api_v3.errors.code_500") }

  context "when the exception is known to be problematic" do
    let(:exception) { ActiveRecord::StatementInvalid.new }

    it "hides the sensitive message" do
      expect(subject.message).to eq(generic_message)
    end
  end

  context "when the exception is something else" do
    let(:exception) { StandardError.new }

    it "includes the sensitive message" do
      expect(subject.message).to include(sensitive_message)
    end

    it "Starts with the generic message" do
      expect(subject.message).to start_with(generic_message)
    end
  end
end
