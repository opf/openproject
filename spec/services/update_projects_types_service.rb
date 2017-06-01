#-- encoding: UTF-8
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

require 'spec_helper'

describe UpdateProjectsTypesService do
  let(:project) { double(Project, types_used_by_work_packages: []) }
  let(:type) { double(Type, id: 456, name: 'A type') }
  let(:standard_type) { double('StandardType', id: 123) }
  let(:instance) { described_class.new(project) }

  before do
    allow(Type).to receive(:standard_type).and_return standard_type
  end

  describe '.call' do
    context 'with ids provided' do
      let(:ids) { [1, 2, 3] }

      it 'returns true and updates the ids' do
        expect(project).to receive(:type_ids=).with(ids)

        expect(instance.call(ids)).to be_truthy
      end
    end

    context 'with no id passed' do
      let(:ids) { [] }

      it 'adds the id of the default type and returns true' do
        expect(project).to receive(:type_ids=).with([standard_type.id])

        expect(instance.call(ids)).to be_truthy
      end
    end

    context 'with nil passed' do
      let(:ids) { nil }

      it 'adds the id of the default type and returns true' do
        expect(project).to receive(:type_ids=).with([standard_type.id])

        expect(instance.call(ids)).to be_truthy
      end
    end

    context 'the id of a type in use is not provided' do
      before do
        allow(project).to receive(:types_used_by_work_packages).and_return([type])
      end

      it 'returns false and sets an error message' do
        ids = [1]

        errors = double('Errors')
        expect(project).to receive(:errors).and_return(errors)
        expect(errors).to receive(:add).with(:type, :in_use_by_work_packages, types: type.name)

        expect(project).to_not receive(:type_ids=)

        expect(instance.call(ids)).to be_falsey
      end
    end
  end
end
