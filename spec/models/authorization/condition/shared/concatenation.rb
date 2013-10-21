#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module Spec
  module Authorization
    module Condition
      module Concatenation
        shared_examples "has first and second condition" do
          describe :first do
            it 'returns the conditions set in the initializer' do
              expect(instance.first).to eq(first_condition)
            end

            it 'allows for setting first via a setter' do
              condition = double('condition')

              instance.first = condition

              expect(instance.first).to eq(condition)
            end
          end

          describe :second do
            it 'returns the conditions set in the initializer' do
              expect(instance.second).to eq(second_condition)
            end

            it 'allows for setting second via a setter' do
              condition = double('condition')

              instance.second = condition

              expect(instance.second).to eq(condition)
            end
          end
        end

        shared_examples "concatenates arel" do |method|
          describe :to_arel do
            let(:first_arel) { double('first_arel') }
            let(:second_arel) { double('first_arel') }
            let(:concatenation) { double('concatenation') }

            before do
              first_condition.stub(:to_arel).and_return(first_arel)
              second_condition.stub(:to_arel).and_return(second_arel)

              first_arel.stub(method).with(second_arel).and_return(concatenation)
            end

            it "should return or concatenated conditions if both are non nil" do
              expect(instance.to_arel).to eq(concatenation)
            end

            it "should return first's arel if second's is nil" do
              second_condition.stub(:to_arel).and_return(nil)

              expect(instance.to_arel).to eq(first_arel)
            end

            it "should return second's arel if first's is nil" do
              first_condition.stub(:to_arel).and_return(nil)

              expect(instance.to_arel).to eq(second_arel)
            end

            it "should return nil if first's and second's arel is nil" do
              first_condition.stub(:to_arel).and_return(nil)
              second_condition.stub(:to_arel).and_return(nil)

              expect(instance.to_arel).to eq(nil)
            end
          end

        end
      end
    end
  end
end
