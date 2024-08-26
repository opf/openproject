# --copyright
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
# ++

require "spec_helper"

RSpec.describe API::V3::Values::PropertyDateRepresenter, "rendering" do
  subject(:generated) { representer.to_json }

  let(:property) { "abc" }
  let(:date_value) { Date.current }
  let(:key_value) { Struct.new(:property, :value, keyword_init: true).new(property:, value: date_value) }
  let(:self_link) { "api/bogus/value" }
  let(:representer) do
    described_class.new key_value, self_link:
  end

  describe "self link" do
    it_behaves_like "has an untitled link" do
      let(:link) { "self" }
      let(:href) { self_link }
    end
  end

  describe "properties" do
    describe "_type" do
      it_behaves_like "property", :_type do
        let(:value) { "Values::Property" }
      end
    end

    describe "property" do
      it_behaves_like "property", :property do
        let(:value) { property }
      end

      context "with a snake_case property" do
        let(:property) { "snake_case" }

        it_behaves_like "property", :property do
          let(:value) { "snakeCase" }
        end
      end
    end

    describe "value" do
      it_behaves_like "date property", :value do
        let(:value) { date_value }
      end

      context "with an empty value" do
        let(:date_value) { nil }

        it_behaves_like "date property", :value do
          let(:value) { nil }
        end
      end
    end
  end
end
