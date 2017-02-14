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

shared_examples_for 'filter dependency' do
  it_behaves_like 'has basic schema properties' do
    let(:name) { 'Values' }
    let(:required) { true }
    let(:writable) { true }
    let(:has_default) { false }
  end

  it_behaves_like 'has no visibility property'

  it_behaves_like 'does not link to allowed values'

  context 'when embedding' do
    let(:form_embedded) { true }

    it_behaves_like 'does not link to allowed values'
  end
end

shared_examples_for 'filter dependency with allowed link' do
  it_behaves_like 'has basic schema properties' do
    let(:name) { 'Values' }
    let(:required) { true }
    let(:writable) { true }
    let(:has_default) { false }
  end

  it_behaves_like 'has no visibility property'

  it_behaves_like 'does not link to allowed values'

  context 'when embedding' do
    let(:form_embedded) { true }

    it_behaves_like 'links to allowed values via collection link'
  end
end

shared_examples_for 'filter dependency with allowed value link collection' do
  it_behaves_like 'has basic schema properties' do
    let(:name) { 'Values' }
    let(:required) { true }
    let(:writable) { true }
    let(:has_default) { false }
  end

  it_behaves_like 'has no visibility property'

  it_behaves_like 'does not link to allowed values'

  context 'when embedding' do
    let(:form_embedded) { true }

    it_behaves_like 'links to allowed values directly'
  end
end

shared_examples_for 'filter dependency empty' do
  it 'is an empty object' do
    is_expected
      .to be_json_eql({}.to_json)
  end
end
