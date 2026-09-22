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

RSpec.configure do |config|
  config.define_derived_metadata :without_ee do
    fail ArgumentError, "without_ee metadata does nothing"
  end

  config.before do |example|
    available_features = Array(example.metadata[:with_ee])
    trial = !!example.metadata[:with_ee_trial]
    next if available_features.empty? && !trial

    # partial double of OpenProject::Token with available features
    token_object = OpenProject::Token.new
    allow(token_object).to receive_messages(available_features:, trial?: trial)

    # partial double of EnterpriseToken returning the partial double of token object
    enterprise_token = EnterpriseToken.new
    allow(enterprise_token).to receive_messages(token_object:)

    # To ensure tests don't trip up on the trial teaser banner
    if trial
      allow(enterprise_token).to receive(:days_left).and_return(42)
    end

    # EnterpriseToken is mocked to return the partial double of enterprise
    # token as active token
    allow(EnterpriseToken).to receive(:active_tokens).and_return([enterprise_token])
  end
end
