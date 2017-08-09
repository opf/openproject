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

describe OpenProject::Design do
  it 'detects variable names in strings' do
    expect('$bla' =~ described_class::VARIABLE_NAME_RGX).to be_truthy
    expect('$bla-asdf' =~ described_class::VARIABLE_NAME_RGX).to be_truthy
    expect('$bla-asdf-12' =~ described_class::VARIABLE_NAME_RGX).to be_truthy
    expect('$bla-asdf12' =~ described_class::VARIABLE_NAME_RGX).to be_truthy
    expect('$12' =~ described_class::VARIABLE_NAME_RGX).to be_truthy
    expect('12' =~ described_class::VARIABLE_NAME_RGX).to be_falsey
    expect('asdf' =~ described_class::VARIABLE_NAME_RGX).to be_falsey
    expect('bla $blub' =~ described_class::VARIABLE_NAME_RGX).to be_truthy
    expect('bla($blub 1px)' =~ described_class::VARIABLE_NAME_RGX).to be_truthy
  end

  context 'default variables set' do
    before do
      stub_const("OpenProject::Design::DEFAULTS",
                 'variable_1' => 'one',
                 'variable_2' => 'two',
                 'variable_1_2' => 'foo $variable_1 bar $variable_2')
    end

    it '#resolved_variables' do
      expect(described_class.resolved_variables).to be_eql(
        'variable_1' => 'one',
        'variable_2' => 'two',
        'variable_1_2' => 'foo one bar two'
      )
    end
  end
end
