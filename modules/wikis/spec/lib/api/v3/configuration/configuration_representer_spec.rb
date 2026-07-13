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

RSpec.describe API::V3::Configuration::ConfigurationRepresenter do
  include API::V3::Utilities::PathHelper

  let(:represented) { Setting }
  let(:current_user) do
    build_stubbed(:user).tap do |user|
      allow(user)
        .to receive(:preference)
        .and_return(build_stubbed(:user_preference))
    end
  end
  let(:embed_links) { false }
  let(:representer) do
    described_class.new(represented, current_user:, embed_links:)
  end

  subject { representer.to_json }

  describe "wikisAvailable" do
    context "when there is at least one enabled wiki" do
      before do
        create(:internal_wiki_provider, enabled: false)
        create(:xwiki_provider)
      end

      it "is true" do
        expect(subject).to be_json_eql(true.to_json).at_path("wikisAvailable")
      end
    end

    context "when there is no enabled wiki" do
      before do
        create(:internal_wiki_provider, enabled: false)
      end

      it "is false" do
        expect(subject).to be_json_eql(false.to_json).at_path("wikisAvailable")
      end
    end

    context "when only the internal wiki provider exists and is enabled (default database state)" do
      before do
        create(:internal_wiki_provider)
      end

      it "is true" do
        expect(subject).to be_json_eql(true.to_json).at_path("wikisAvailable")
      end
    end

    context "when there are no wikis at all (unexpected database state)" do
      it "is false" do
        expect(subject).to be_json_eql(false.to_json).at_path("wikisAvailable")
      end
    end
  end
end
