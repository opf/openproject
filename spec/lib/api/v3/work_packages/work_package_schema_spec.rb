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

describe ::API::V3::WorkPackages::Schema::WorkPackageSchema do
  let(:project) {
    double('Project', cost_objects: double('CostObjects'))
  }
  let(:type) { FactoryGirl.build(:type) }
  let(:work_package) { FactoryGirl.build(:work_package, project: project, type: type) }

  describe '#assignable_cost_objects' do
    subject { described_class.new(project: project, type: type) }

    it 'returns project.cost_objects' do
      expect(subject.assignable_cost_objects).to eql(project.cost_objects)
    end

    context 'project is nil' do
      let(:project) { nil }
      subject { described_class.new(work_package: work_package) }

      it 'returns nil' do
        expect(subject.assignable_cost_objects).to eql(nil)
      end
    end
  end
end
