#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

require 'spec_helper'

describe UpdateProjectsTypesService do
  let(:project) { instance_double(Project, types_used_by_work_packages: []) }
  let(:standard_type) { build_stubbed(:type_standard) }

  subject(:instance) { described_class.new(project) }

  before do
    allow(Type).to receive(:standard_type).and_return standard_type
  end

  describe '.call' do
    before do
      allow(project).to receive(:type_ids=)
    end

    context 'with ids provided' do
      let(:ids) { [1, 2, 3] }

      it 'returns true and updates the ids' do
        expect(instance.call(ids)).to be_truthy
        expect(project).to have_received(:type_ids=).with(ids)
      end
    end

    context 'with no id passed' do
      let(:ids) { [] }

      it 'adds the id of the default type and returns true' do
        expect(instance.call(ids)).to be_truthy
        expect(project).to have_received(:type_ids=).with([standard_type.id])
      end
    end

    context 'with nil passed' do
      let(:ids) { nil }

      it 'adds the id of the default type and returns true' do
        expect(instance.call(ids)).to be_truthy
        expect(project).to have_received(:type_ids=).with([standard_type.id])
      end
    end

    context 'when the id of a type in use is not provided' do
      let(:type) { build_stubbed(:type) }

      before do
        allow(project).to receive(:types_used_by_work_packages).and_return([type])
      end

      it 'returns false and sets an error message' do
        ids = [1]

        errors = instance_double(ActiveModel::Errors)
        allow(errors).to receive(:add)
        allow(project).to receive(:errors).and_return(errors)

        expect(instance.call(ids)).to be_falsey
        expect(errors).to have_received(:add).with(:types, :in_use_by_work_packages, types: type.name)
        expect(project).not_to have_received(:type_ids=)
      end
    end
  end
end
