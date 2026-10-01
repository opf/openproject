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

RSpec.describe Queries::Users::Selects::ConsentedAt do
  describe ".key" do
    it "is :consented_at" do
      expect(described_class.key).to eq(:consented_at)
    end
  end

  describe "#caption" do
    it "is the user attribute name" do
      expect(described_class.new(:consented_at).caption).to eq(User.human_attribute_name(:consented_at))
    end
  end

  context "when consent is required", with_settings: { consent_required: true } do
    it "is available" do
      expect(UserQuery.new.available_selects).to include(an_instance_of(described_class))
    end

    it "is selectable" do
      query = UserQuery.new(name: "Users").tap { it.select(:consented_at) }

      expect(query.selects.last).to be_a(described_class)
    end
  end

  context "when consent is not required", with_settings: { consent_required: false } do
    it "is not available" do
      expect(UserQuery.new.available_selects).not_to include(an_instance_of(described_class))
    end

    it "does not resolve to the select" do
      query = UserQuery.new(name: "Users").tap { it.select(:consented_at) }

      expect(query.selects.last).to be_a(Queries::Selects::NotExistingSelect)
    end
  end
end
