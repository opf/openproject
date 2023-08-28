#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'

RSpec.describe API::V3::WorkPackages::Schema::SpecificWorkPackageSchema do
  let(:project) { build(:project) }
  let(:type) { build(:type) }
  let(:work_package) { build(:work_package, project:, type:) }
  let(:current_user) do
    build_stubbed(:user).tap do |user|
      allow(user).to receive(:allowed_to?).and_return(true)
    end
  end

  shared_examples_for 'with parent which is a BACKLOGS type' do |writable|
    let(:parent) { create(:work_package, type: type_task) }

    before do
      work_package.parent_id = parent.id
      work_package.save!
    end

    it "is #{'not' unless writable} writable" do
      if writable
        expect(subject).to be_writable(:version)
      else
        expect(subject).not_to be_writable(:version)
      end
    end
  end

  shared_examples_for 'with parent which is not a BACKLOGS type' do
    let(:parent) { create(:work_package, type: type_feature) }

    before do
      work_package.parent_id = parent.id
      work_package.save!
    end

    it "is writable" do
      expect(subject).to be_writable(:version)
    end
  end

  before do
    login_as(current_user)
  end

  describe '#writable? for remaining_hours' do
    subject { described_class.new(work_package:) }

    context 'work_package is a leaf' do
      before do
        allow(work_package).to receive(:leaf?).and_return(true)
      end

      it 'is writable' do
        expect(subject).to be_writable(:remaining_hours)
      end
    end

    context 'work_package is no leaf' do
      before do
        allow(work_package).to receive(:leaf?).and_return(false)
      end

      it 'is not writable' do
        expect(subject).not_to be_writable(:remaining_hours)
      end
    end
  end

  describe '#version_writable?' do
    subject { described_class.new(work_package:) }

    let(:type_task) { create(:type_task) }
    let(:type_feature) { create(:type_feature) }

    before do
      allow(WorkPackage).to receive(:backlogs_types).and_return([type_task.id])
      allow(work_package).to receive(:backlogs_enabled?).and_return(true)
    end

    describe 'work_package is a task' do
      before do
        allow(work_package)
          .to receive(:is_task?)
          .and_return(true)
      end

      it_behaves_like 'with parent which is a BACKLOGS type', false
      it_behaves_like 'with parent which is not a BACKLOGS type'
    end

    describe 'work_package is no task' do
      before do
        allow(work_package)
          .to receive(:is_task?)
          .and_return(false)
      end

      it_behaves_like 'with parent which is a BACKLOGS type', true
      it_behaves_like 'with parent which is not a BACKLOGS type'
    end
  end
end
