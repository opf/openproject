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

RSpec.describe Queries::Filters::AvailableFilters do
  let(:context) { build_stubbed(:project) }
  let(:register) { Queries::FilterRegister }
  let(:includer) do
    query_class = Class.new do
      attr_accessor :context

      def initialize(context)
        self.context = context
      end

      include Queries::Filters::AvailableFilters
    end
    includer = query_class.new(context)

    allow(Queries::Register)
      .to receive(:filters)
      .and_return(query_class => registered_filters)

    includer
  end

  describe "#filter_for" do
    let(:registered_filters) { [filter1, filter2] }

    let(:filter1_available) { true }
    let(:filter1_key) { :filter1 }
    let(:filter1_name) { :filter1 }
    let(:filter1_instance) do
      instance_double(Queries::Filters::Base,
                      available?: filter1_available,
                      name: filter1_name)
    end
    let(:filter1) do
      class_double(Queries::Filters::Base,
                   key: filter1_key,
                   create!: filter1_instance,
                   all_for: filter1_instance)
    end

    let(:filter2_available) { true }
    let(:filter2_key) { /f\d+/ }
    let(:filter2_name) { :f2 }
    let(:filter2_instance) do
      instance_double(Queries::Filters::Base,
                      available?: filter2_available,
                      name: filter2_name)
    end

    let(:filter2) do
      class_double(Queries::Filters::Base,
                   key: filter2_key,
                   create!: filter2_instance,
                   all_for: filter2_instance)
    end

    context "for a filter identified by a symbol" do
      let(:registered_filters) { [filter1, filter2] }

      context "if available" do
        it "returns an instance of the matching filter" do
          expect(includer.filter_for(:filter1)).to eql filter1_instance
        end

        it "returns the NotExistingFilter if the name is not matched" do
          expect(includer.filter_for(:not_a_filter_name)).to be_a Queries::Filters::NotExistingFilter
        end
      end

      context "if not available" do
        let(:filter1_available) { false }

        it "returns the NotExistingFilter if the name is not matched" do
          expect(includer.filter_for(:not_a_filter_name)).to be_a Queries::Filters::NotExistingFilter
        end

        it "is ignored and returns the filter if the name is matched" do
          expect(includer.filter_for(:filter1)).to eq(filter1_instance)
          expect(includer.filter_for(:filter1, no_memoization: true)).to eq(filter1_instance)
          expect(includer.filter_for(:filter1, no_memoization: false)).to eq(filter1_instance)
        end
      end
    end

    context "for a filter identified by a regexp" do
      context "if available" do
        it "returns an instance of the matching filter" do
          expect(includer.filter_for(:f2)).to eq(filter2_instance)
        end

        it "returns the NotExistingFilter if the key is not matched" do
          expect(includer.filter_for(:fi1)).to be_a Queries::Filters::NotExistingFilter
        end

        it "returns the NotExistingFilter if the key is matched but the name is not" do
          expect(includer.filter_for(:f42)).to be_a Queries::Filters::NotExistingFilter
        end
      end

      context "if unavailable" do
        let(:filter2_available) { false }

        it "is ignored and returns the matching filter" do
          expect(includer.filter_for(:f2)).to eq(filter2_instance)
        end
      end
    end
  end
end
