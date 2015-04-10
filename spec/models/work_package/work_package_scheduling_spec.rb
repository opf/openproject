#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

describe WorkPackage, type: :model do
  describe '#overdue' do
    let(:work_package) {
      FactoryGirl.create(:work_package,
                         due_date: due_date)
    }

    shared_examples_for 'overdue' do
      subject { work_package.overdue? }

      it { is_expected.to be_truthy }
    end

    shared_examples_for 'on time' do
      subject { work_package.overdue? }

      it { is_expected.to be_falsey }
    end

    context 'one day ago' do
      let(:due_date) { 1.day.ago.to_date }

      it_behaves_like 'overdue'
    end

    context 'today' do
      let(:due_date) { Date.today.to_date }

      it_behaves_like 'on time'
    end

    context 'next day' do
      let(:due_date) { 1.day.from_now.to_date }

      it_behaves_like 'on time'
    end

    context 'no due date' do
      let(:due_date) { nil }

      it_behaves_like 'on time'
    end

    context 'status closed' do
      let(:due_date) { 1.day.ago.to_date }
      let(:status) {
        FactoryGirl.create(:status,
                           is_closed: true)
      }

      before { work_package.status = status }

      it_behaves_like 'on time'
    end
  end

  describe '#behind_schedule?' do
    let(:work_package) {
      FactoryGirl.create(:work_package,
                         start_date: start_date,
                         due_date: due_date,
                         done_ratio: done_ratio)
    }

    shared_examples_for 'behind schedule' do
      subject { work_package.behind_schedule? }

      it { is_expected.to be_truthy }
    end

    shared_examples_for 'in schedule' do
      subject { work_package.behind_schedule? }

      it { is_expected.to be_falsey }
    end

    context 'no start date' do
      let(:start_date) { nil }
      let(:due_date) { 1.day.from_now.to_date }
      let(:done_ratio) { 0 }

      it_behaves_like 'in schedule'
    end

    context 'no end date' do
      let(:start_date) { 1.day.from_now.to_date }
      let(:due_date) { nil }
      let(:done_ratio) { 0 }

      it_behaves_like 'in schedule'
    end

    context "more done than it's calendar time" do
      let(:start_date) { 50.day.ago.to_date }
      let(:due_date) { 50.day.from_now.to_date }
      let(:done_ratio) { 90 }

      it_behaves_like 'in schedule'
    end

    context 'not started' do
      let(:start_date) { 1.day.ago.to_date }
      let(:due_date) { 1.day.from_now.to_date }
      let(:done_ratio) { 0 }

      it_behaves_like 'behind schedule'
    end

    context "more done than it's calendar time" do
      let(:start_date) { 100.day.ago.to_date }
      let(:due_date) { Date.today }
      let(:done_ratio) { 90 }

      it_behaves_like 'behind schedule'
    end
  end
end
