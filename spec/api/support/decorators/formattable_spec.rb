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

describe ::API::Decorators::Formattable do
  let(:represented) { 'A *raw* string!' }
  subject { described_class.new(represented).to_json }

  before do
    allow(Setting).to receive(:text_formatting).and_return('textile')
  end

  it 'should indicate its format' do
    is_expected.to be_json_eql('textile'.to_json).at_path('format')
  end

  it 'should contain the raw string' do
    is_expected.to be_json_eql(represented.to_json).at_path('raw')
  end

  it 'should contain the formatted string' do
    is_expected.to be_json_eql('<p>A <strong>raw</strong> string!</p>'.to_json).at_path('html')
  end

  context 'format specified explicitly' do
    subject { described_class.new(represented, format: 'plain').to_json }

    it 'should indicate the explicit format' do
      is_expected.to be_json_eql('plain'.to_json).at_path('format')
    end

    it 'should format using the explicit format' do
      is_expected.to be_json_eql('<p>A *raw* string!</p>'.to_json).at_path('html')
    end
  end

  context 'format set to plain by Settings' do
    before do
      # N.B. Settings may return '' even though they mean 'plain'
      allow(Setting).to receive(:text_formatting).and_return('')
    end

    it 'should indicate the plain format' do
      is_expected.to be_json_eql('plain'.to_json).at_path('format')
    end

    it 'should format using the plain format' do
      is_expected.to be_json_eql('<p>A *raw* string!</p>'.to_json).at_path('html')
    end
  end
end
