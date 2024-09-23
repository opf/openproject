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

RSpec.describe Queries::Notifications::Filters::ReasonFilter do
  it_behaves_like "basic query filter" do
    let(:class_key) { :reason }
    let(:type) { :list }
    let(:model) { Notification }
    let(:attribute) { :reason }
    let(:values) { ["mentioned"] }

    it_behaves_like "non ar filter"

    describe "#allowed_values" do
      context "with enterprise", with_ee: %i[date_alerts] do
        it "contains all the REASONS" do
          expect(instance.allowed_values).to eq(described_class::REASONS.keys.map { |r| [r, r] })
        end
      end

      context "without enterprise", with_ee: false do
        it "does not contains date alerts" do
          expect(instance.allowed_values)
            .to eq(described_class::REASONS.keys.without("dateAlert").map { |r| [r, r] })
        end
      end
    end
  end
end
