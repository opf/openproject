#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

describe Reporting, type: :model do
  describe '- Relations ' do
    describe '#project' do
      it 'can read the project w/ the help of the belongs_to association' do
        project   = FactoryGirl.create(:project)
        reporting = FactoryGirl.create(:reporting,
                                       project_id: project.id)

        reporting.reload

        expect(reporting.project).to eq(project)
      end

      it 'can read the reporting_to_project w/ the help of the belongs_to association' do
        project   = FactoryGirl.create(:project)
        reporting = FactoryGirl.create(:reporting,
                                       reporting_to_project_id: project.id)

        reporting.reload

        expect(reporting.reporting_to_project).to eq(project)
      end

      it 'can read the reported_project_status w/ the help of the belongs_to association' do
        reported_project_status = FactoryGirl.create(:reported_project_status)
        reporting               = FactoryGirl.create(:reporting,
                                                     reported_project_status_id: reported_project_status.id)

        reporting.reload

        expect(reporting.reported_project_status).to eq(reported_project_status)
      end
    end
  end

  describe '- Validations ' do
    let(:attributes) {
      { project_id: 1,
        reporting_to_project_id: 2 }
    }

    before {
      FactoryGirl.create(:project, id: 1)
      FactoryGirl.create(:project, id: 2)
    }

    it { expect(Reporting.new.tap { |r| r.send(:assign_attributes, attributes) }).to be_valid }

    describe 'project' do
      it 'is invalid w/o a project' do
        attributes[:project_id] = nil
        reporting = Reporting.new
        reporting.send(:assign_attributes, attributes)

        expect(reporting).not_to be_valid

        expect(reporting.errors[:project]).to be_present
        expect(reporting.errors[:project]).to eq(["can't be blank."])
      end
    end

    describe 'reporting_to_project' do
      it 'is invalid w/o a reporting_to_project' do
        attributes[:reporting_to_project_id] = nil
        reporting = Reporting.new
        reporting.send(:assign_attributes, attributes)

        expect(reporting).not_to be_valid

        expect(reporting.errors[:reporting_to_project]).to be_present
        expect(reporting.errors[:reporting_to_project]).to eq(["can't be blank."])
      end
    end
  end
end
