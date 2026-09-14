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

RSpec.describe Queries::Users::Filters::ConsentedAtFilter do
  it_behaves_like "basic query filter" do
    let(:class_key) { :consented_at }
    let(:type) { :datetime_past }
    let(:model) { User }
    let(:attribute) { :consented_at }
    let(:values) { ["3"] }
    let(:human_name) { User.human_attribute_name(:consented_at) }

    describe "#available?" do
      it "is true when consent is required", with_settings: { consent_required: true } do
        expect(instance).to be_available
      end

      it "is false when consent is not required", with_settings: { consent_required: false } do
        expect(instance).not_to be_available
      end
    end
  end

  describe "being offered by the query" do
    current_user { create(:admin) }

    it "is offered when consent is required", with_settings: { consent_required: true } do
      expect(UserQuery.new.available_filters.map(&:name)).to include(:consented_at)
    end

    it "is not offered when consent is not required", with_settings: { consent_required: false } do
      expect(UserQuery.new.available_filters.map(&:name)).not_to include(:consented_at)
    end
  end

  describe "#apply_to" do
    shared_let(:consented_recently) { create(:user, consented_at: 2.days.ago) }
    shared_let(:consented_long_ago) { create(:user, consented_at: 2.years.ago) }
    shared_let(:never_consented) { create(:user, consented_at: nil) }

    let(:instance) do
      described_class.create!(name: :consented_at, operator: ">t-", values: ["7"])
    end

    it "keeps only the users who consented within the given number of days" do
      expect(instance.apply_to(User.user).to_a).to contain_exactly(consented_recently)
    end
  end
end
