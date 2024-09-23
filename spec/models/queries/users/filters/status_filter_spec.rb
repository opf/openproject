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

RSpec.describe Queries::Users::Filters::StatusFilter do
  it_behaves_like "basic query filter" do
    let(:class_key) { :status }
    let(:type) { :list }

    describe "#allowed_values" do
      it "is a list of the possible values" do
        expected = Principal.statuses.keys.map do |key|
          [I18n.t(:"status_#{key}"), key]
        end

        expect(instance.allowed_values).to match_array(expected)
      end
    end
  end

  describe "#apply_to" do
    include_context "filter tests"
    let(:values) { %w[active invited] }
    let(:model) { User.user }

    context 'for "="' do
      let(:operator) { "=" }

      it "is the same as handwriting the query" do
        expected = model.where("users.status IN (1,4)")

        expect(instance.apply_to(model).to_sql).to eql expected.to_sql
      end
    end
  end
end
