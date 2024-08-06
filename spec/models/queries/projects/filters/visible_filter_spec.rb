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

RSpec.describe Queries::Projects::Filters::VisibleFilter do
  it_behaves_like "basic query filter" do
    let(:class_key) { :visible }
    let(:type) { :list }
    let(:model) { Project }
    let(:attribute) { :visible }
    let(:values) { ["5"] }

    describe "#available_operators" do
      it "supports only =" do
        expect(instance.available_operators)
          .to eql [Queries::Operators::Equals]
      end
    end

    describe "#valid?" do
      before do
        allow(User)
          .to receive(:pluck)
                .and_return([[5, 5], [8, 8]])
      end

      context "without values" do
        let(:values) { [] }

        it "is invalid" do
          expect(instance)
            .to be_invalid
        end
      end

      context "with valid value" do
        it "is valid" do
          expect(instance)
            .to be_valid
        end
      end

      context "with multiple valid values" do
        let(:values) { %w[5 8] }

        it "is invalid" do
          expect(instance)
            .to be_invalid
        end
      end
    end
  end
end
