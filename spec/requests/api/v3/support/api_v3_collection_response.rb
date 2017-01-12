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

shared_examples_for 'API V3 collection response' do |total, count, type|
  subject { response.body }

  it { expect(response.status).to eql(200) }

  it { is_expected.to be_json_eql('Collection'.to_json).at_path('_type') }

  it { is_expected.to be_json_eql(count.to_json).at_path('count') }

  it { is_expected.to be_json_eql(total.to_json).at_path('total') }

  it { is_expected.to have_json_size(count) .at_path('_embedded/elements') }

  it 'has element of specified type if elements exist' do
    if count > 0
      is_expected.to be_json_eql(type.to_json).at_path('_embedded/elements/0/_type')
    end
  end
end
