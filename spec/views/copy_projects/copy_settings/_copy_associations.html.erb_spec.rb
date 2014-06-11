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

describe 'copy_projects/copy_settings/_copy_associations' do
  let(:project) { FactoryGirl.create(:project) }
  let(:copy_project) { Project.copy_attributes(project) }
  let!(:work_package) { FactoryGirl.create(:work_package, project: project) }

  before do
    assign(:project, project)
    assign(:copy_project, copy_project)
  end

  describe 'work package' do
    describe 'copy limit' do
      context 'not exceeded' do
        before do
          assign(:copy_work_packages, false)
          render template: "copy_projects/copy_settings/_copy_associations", locals: { project: project }
        end
        
        it { expect(response.body).not_to have_selector("label input#only_work_packages") }
      end

      context 'not exceeded' do
        before do
          assign(:copy_work_packages, true)
          render template: "copy_projects/copy_settings/_copy_associations", locals: { project: project }
        end

        it { expect(response.body).to have_selector("label input#only_work_packages") }
      end
    end
  end
end
