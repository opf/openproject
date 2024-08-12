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

RSpec.describe WorkPackage do
  describe "#overdue" do
    let(:work_package) do
      create(:work_package,
             due_date:)
    end

    shared_examples_for "overdue" do
      subject { work_package.overdue? }

      it { is_expected.to be_truthy }
    end

    shared_examples_for "on time" do
      subject { work_package.overdue? }

      it { is_expected.to be_falsey }
    end

    context "one day ago" do
      let(:due_date) { 1.day.ago.to_date }

      it_behaves_like "overdue"
    end

    context "today" do
      let(:due_date) { Date.today.to_date }

      it_behaves_like "on time"
    end

    context "next day" do
      let(:due_date) { 1.day.from_now.to_date }

      it_behaves_like "on time"
    end

    context "no finish date" do
      let(:due_date) { nil }

      it_behaves_like "on time"
    end

    context "status closed" do
      let(:due_date) { 1.day.ago.to_date }
      let(:status) do
        create(:status,
               is_closed: true)
      end

      before do
        work_package.status = status
      end

      it_behaves_like "on time"
    end
  end
end
