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

RSpec.describe Queries::WorkPackages::Filter::DurationFilter do
  it_behaves_like "basic query filter" do
    let(:type) { :integer }
    let(:class_key) { :duration }

    describe "#available?" do
      it "is true" do
        expect(instance).to be_available
      end
    end

    describe "#allowed_values" do
      it "is nil" do
        expect(instance.allowed_values).to be_nil
      end
    end

    it_behaves_like "non ar filter"

    describe "#where" do
      # TODO: 0 duration should not happen in 12.x. Should we remove it?
      let!(:work_package_zero_duration) { create(:work_package, duration: 0) }
      let!(:work_package_no_duration) { create(:work_package, duration: nil) }
      let!(:work_package_with_duration) { create(:work_package, duration: 1) }
      let!(:work_package_with_milestone) { create(:work_package, duration: 1, type: create(:type_milestone)) }
      let(:values) { [1] }

      subject { WorkPackage.joins(instance.joins).where(instance.where) }

      context 'with the operator being "none"' do
        before do
          instance.operator = Queries::Operators::None.to_sym.to_s
        end

        it "finds zero and none values also including milestones" do
          expect(subject).to contain_exactly(work_package_zero_duration, work_package_no_duration, work_package_with_milestone)
        end
      end

      it "does not returns milestone work packages" do
        expect(subject).to contain_exactly(work_package_with_duration)
      end
    end
  end
end
