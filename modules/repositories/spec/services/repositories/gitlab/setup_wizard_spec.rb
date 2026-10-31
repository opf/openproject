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

RSpec.describe Repositories::Gitlab::SetupWizard do
  subject(:wizard) { described_class.new(model: provider, user: create(:admin)) }

  context "with a new provider" do
    let(:provider) { Repositories::GitlabProvider.new }

    it "starts with the general information" do
      expect(wizard.prepare_next_step).to eq(:general_information)
    end
  end

  context "with a provider without a configured webhook user" do
    let(:provider) { create(:repository_provider) }

    it "asks for the webhook user" do
      expect(wizard.prepare_next_step).to eq(:webhook_user)
    end
  end

  context "with a provider whose webhook user was left blank" do
    let(:provider) { create(:repository_provider, gitlab_user_id: nil) }

    it "continues with the webhook and generates its secret" do
      expect(wizard.prepare_next_step).to eq(:webhook)
      expect(provider.reload.webhook_secret).to match(/\A\h{64}\z/)
    end
  end

  context "with a completely configured provider" do
    let(:provider) { create(:repository_provider, gitlab_user_id: nil, webhook_secret: "secret") }

    it "has no next step" do
      expect(wizard.prepare_next_step).to be_nil
    end
  end
end
