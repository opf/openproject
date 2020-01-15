#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ::API::Decorators::Formattable do
  let(:represented) { 'A **raw** string!' }
  subject { described_class.new(represented).to_json }

  it 'should indicate its format' do
    is_expected.to be_json_eql('markdown'.to_json).at_path('format')
  end

  it 'should contain the raw string' do
    is_expected.to be_json_eql(represented.to_json).at_path('raw')
  end

  it 'should contain the formatted string' do
    is_expected.to be_json_eql('<p>A <strong>raw</strong> string!</p>'.to_json).at_path('html')
  end

  context 'passing an object context' do
    let(:object) { FactoryBot.build_stubbed :work_package }
    subject { described_class.new(represented, object: object) }

    it 'passes that to format_text' do
      expect(subject)
        .to receive(:format_text).with(anything, format: :markdown, object: object)
        .and_call_original

      expect(subject.to_json)
        .to be_json_eql('<p>A <strong>raw</strong> string!</p>'.to_json).at_path('html')
    end
  end

  context 'format specified explicitly' do
    subject { described_class.new(represented, plain: true).to_json }

    it 'should indicate the explicit format' do
      is_expected.to be_json_eql('plain'.to_json).at_path('format')
    end

    it 'should format using the explicit format' do
      is_expected.to be_json_eql('<p>A **raw** string!</p>'.to_json).at_path('html')
    end
  end
end
