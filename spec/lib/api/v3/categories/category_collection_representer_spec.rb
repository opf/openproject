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

describe ::API::V3::Categories::CategoryCollectionRepresenter do
  let(:project)    { FactoryGirl.build(:project, id: 888) }
  let(:categories) { FactoryGirl.build_list(:category, 3) }
  let(:models)     { categories.map { |category|
    ::API::V3::Categories::CategoryModel.new(category)
  } }
  let(:representer) { described_class.new(models, project: project) }

  describe '#initialize' do
    context 'with incorrect parameters' do
      it 'should raise without a project' do
        expect { described_class.new(models) }.to raise_error
      end
    end
  end

  context 'generation' do
    subject(:generated) { representer.to_json }

    it { should include_json('Categories'.to_json).at_path('_type') }

    it { should have_json_type(Object).at_path('_links') }
    it 'should link to self' do
      expect(generated).to have_json_path('_links/self/href')
      expect(parse_json(generated, '_links/self/href')).to match %r{/api/v3/projects/888/categories$}
    end

    describe 'categories' do
      it { should have_json_path('_embedded/categories') }
      it { should have_json_size(3).at_path('_embedded/categories') }
      it { should have_json_path('_embedded/categories/2/name') }
    end
  end
end
