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

require 'spec_helper'

describe ::API::V3::WorkPackages::WorkPackageModel do
  include Capybara::RSpecMatchers

  subject(:model) { ::API::V3::WorkPackages::WorkPackageModel.new(work_package, current_user) }
  let(:work_package) { FactoryGirl.build(:work_package, attributes) }
  let(:current_user) { FactoryGirl.build(:user) }

  context 'with a formatted description' do
    let(:attributes) {
      {
       description: <<-DESC
h2. Plan for this month

# Important bug fixes
# Aesthetic improvements
       DESC
      }
    }

    describe '#description' do
      subject { super().description }
      it { is_expected.to have_selector 'h2' }
    end

    describe '#description' do
      subject { super().description }
      it { is_expected.to have_selector 'ol > li' }
    end

    describe '#raw_description' do
      subject { super().raw_description }
      it { is_expected.to eq attributes[:description] }
    end

    it 'should allow a raw_description to be set' do
      model.raw_description = 'h4. More details'
      expect(model.description).to have_selector 'h4'
    end

    describe 'closed state' do
      context 'is closed' do
        let(:closed_status) { FactoryGirl.build(:closed_status) }
        let(:work_package) { FactoryGirl.build(:work_package, status: closed_status) }

        it { expect(model.is_closed).to be_truthy }
      end

      context 'is not closed' do
        it { expect(model.is_closed).to be_falsey }
      end
    end

    describe 'visibility to related work packages' do
      let(:project) { FactoryGirl.create(:project, is_public: false) }
      let(:forbidden_project) { FactoryGirl.create(:project, is_public: false) }
      let(:user) { FactoryGirl.create(:user, member_in_project: project) }

      let(:work_package) { FactoryGirl.create(:work_package, project: project) }
      let(:work_package_2) { FactoryGirl.create(:work_package, project: project) }
      let(:forbidden_work_package) { FactoryGirl.create(:work_package, project: forbidden_project) }

      before do
        allow(User).to receive(:current).and_return(user)
        allow(Setting).to receive(:cross_project_work_package_relations?).and_return(true)
      end

      describe 'relations' do
        let!(:relation) { FactoryGirl.create(:relation,
                                             from: work_package,
                                             to: work_package_2) }
        let!(:forbidden_relation) { FactoryGirl.create(:relation,
                                                       from: work_package,
                                                       to: forbidden_work_package) }

        it { expect(model.relations.count).to eq(1) }

        it { expect(model.relations[0].from_id).to eq(work_package.id) }

        it { expect(model.relations[0].to_id).to eq(work_package_2.id) }
      end
    end
  end

  describe :estimated_time do
    let(:value) { 6.0 }
    let(:attributes) do
      { estimated_hours: value }
    end

    it 'should have the estimated_hours as the value' do
      expect(model.estimated_time[:value]).to eql(value)
    end

    it 'should have units in de if the language is de' do
      I18n.with_locale(:de) do
        expect(model.estimated_time[:units]).to eql(I18n.t(:'datetime.units.hour',
                                                           count: value.to_i))
      end
    end

    it 'should have units in en if the language is en' do
      I18n.with_locale(:en) do
        expect(model.estimated_time[:units]).to eql(I18n.t(:'datetime.units.hour',
                                                           count: value.to_i))
      end
    end

    it 'should make sense if the hours are 0' do
      work_package.estimated_hours = 0.0

      I18n.with_locale(:en) do
        expect(model.estimated_time[:units]).to eql(I18n.t(:'datetime.units.hour',
                                                           count: 2)) # we want plural on 0
      end
    end
  end
end
