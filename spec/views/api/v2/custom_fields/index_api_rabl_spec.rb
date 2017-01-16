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

describe 'api/v2/custom_fields/index.api.rabl', type: :view do
  before do
    params[:format] = 'xml'
  end

  let(:custom_field_1) do
    FactoryGirl.create :issue_custom_field,
                       name: 'Brot',
                       field_format: 'text',
                       types: [(::Type.find_by(name: 'None') || FactoryGirl.create(:type_standard))]
  end

  let(:custom_field_2) do
    FactoryGirl.create :issue_custom_field,
                       name: 'Belag',
                       field_format: 'text',
                       types: [(::Type.find_by(name: 'None') || FactoryGirl.create(:type_standard))]
  end

  describe 'with two custom fields' do
    before do
      assign(:custom_fields, [custom_field_1, custom_field_2])
      render
    end

    subject { Nokogiri.XML(rendered) }

    it 'renders those custom fields\' attributes' do
      names = subject.xpath('//custom_fields/custom_field/name/text()')
      formats = subject.xpath('//custom_fields/custom_field/field_format/text()')

      expect(names.map(&:to_s)).to eq(['Brot', 'Belag'])
      expect(formats.map(&:to_s)).to eq(['text', 'text'])
    end
  end
end
