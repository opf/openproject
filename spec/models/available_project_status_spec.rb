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

require File.expand_path('../../spec_helper', __FILE__)

describe AvailableProjectStatus, type: :model do
  describe '- Relations ' do
    describe '#project_type' do
      it 'can read the project_type w/ the help of the belongs_to association' do
        project_type = FactoryGirl.create(:project_type)
        available_project_status = FactoryGirl.create(:available_project_status,
                                                      project_type_id: project_type.id)

        available_project_status.reload

        expect(available_project_status.project_type).to eq(project_type)
      end
    end

    describe '#reported_project_status' do
      it 'can read the reported_project_status w/ the help of the belongs_to association' do
        reported_project_status  = FactoryGirl.create(:reported_project_status)
        available_project_status = FactoryGirl.create(:available_project_status,
                                                      reported_project_status_id: reported_project_status.id)

        available_project_status.reload

        expect(available_project_status.reported_project_status).to eq(reported_project_status)
      end
    end
  end

  describe '- Validations ' do
    let(:attributes) {
      { reported_project_status_id: 2,
        project_type_id: 1 }
    }

    before {
      FactoryGirl.create(:project_type, id: 1)
      FactoryGirl.create(:reported_project_status, id: 2)
    }

    it { expect(AvailableProjectStatus.new.tap { |ps| ps.send(:assign_attributes, attributes, without_protection: true) }).to be_valid }

    describe 'project_type' do
      it 'is invalid w/o a project_type' do
        attributes[:project_type_id] = nil
        available_project_status = AvailableProjectStatus.new.tap { |ps| ps.send(:assign_attributes, attributes, without_protection: true) }

        expect(available_project_status).not_to be_valid

        expect(available_project_status.errors[:project_type]).to be_present
        expect(available_project_status.errors[:project_type]).to eq(["can't be blank"])
      end
    end

    describe 'reported_project_status' do
      it 'is invalid w/o a reported_project_status' do
        attributes[:reported_project_status_id] = nil
        available_project_status = AvailableProjectStatus.new.tap { |ps| ps.send(:assign_attributes, attributes, without_protection: true) }

        expect(available_project_status).not_to be_valid

        expect(available_project_status.errors[:reported_project_status]).to be_present
        expect(available_project_status.errors[:reported_project_status]).to eq(["can't be blank"])
      end
    end
  end
end
