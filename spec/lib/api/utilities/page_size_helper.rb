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

describe ::API::Utilities::PageSizeHelper do
  let(:clazz) do
    Class.new do
      include ::API::Utilities::PageSizeHelper
    end
  end
  let(:subject) { clazz.new }

  describe '#maximum_page_size' do
    context 'when small values in per_page_options',
            with_settings: { per_page_options: '20,100' } do

      it 'uses the magical number 500' do
        expect(subject.maximum_page_size).to eq(500)
      end
    end

    context 'when larger values in per_page_options',
            with_settings: { per_page_options: '20,100,1000' } do

      it 'uses that value' do
        expect(subject.maximum_page_size).to eq(1000)
      end
    end
  end
end
