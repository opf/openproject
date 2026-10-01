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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe BasicData::Wikis::InternalProviderSeeder do
  subject { described_class.new(seed_data).seed! }

  let(:seed_data) { Source::SeedData.new({}) }

  it "creates an enabled internal wiki provider" do
    expect { subject }.to change(Wikis::InternalProvider, :count).from(0).to(1)

    expect(Wikis::InternalProvider.first).to be_enabled
  end

  context "when the provider already exists" do
    let(:existing_provider) { create(:internal_wiki_provider, enabled: true) }

    before do
      existing_provider
    end

    it "does not create another internal wiki provider" do
      expect { subject }.not_to change(Wikis::InternalProvider, :count)
    end

    context "when the provider is disabled" do
      let(:existing_provider) { create(:internal_wiki_provider, enabled: false) }

      it "keeps it disabled" do
        expect { subject }.not_to change(Wikis::InternalProvider.first, :enabled?)
      end

      context "when enabling the provider via environment config", with_settings: { internal_wiki_provider: { enabled: true } } do
        it "enables the provider" do
          expect { subject }.to change { Wikis::InternalProvider.first.reload.enabled? }.from(false).to(true)
        end
      end
    end

    context "when disabling the provider via environment config", with_settings: { internal_wiki_provider: { enabled: false } } do
      it "disables the provider" do
        expect { subject }.to change { Wikis::InternalProvider.first.reload.enabled? }.from(true).to(false)
      end
    end
  end
end
