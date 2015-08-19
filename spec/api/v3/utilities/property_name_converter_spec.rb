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

require 'rails_helper'

describe ::API::Utilities::PropertyNameConverter do
  describe '#from_ar_name' do
    let(:attribute_name) { :an_attribute }

    subject { described_class.from_ar_name(attribute_name) }

    it 'stringifies attribute names' do
      is_expected.to be_a(String)
    end

    it 'camelizes attribute names' do
      is_expected.to eql('anAttribute')
    end

    context 'foreign keys' do
      let(:attribute_name) { :thing_id }

      it 'eliminates the id suffix' do
        is_expected.to eql('thing')
      end
    end

    # N.B. not re-iterating all existing known replacements here. Just using a single example
    # to verify that it is done at all
    context 'special replacements' do
      let(:attribute_name) { :assigned_to }

      it 'performs special replacements' do
        is_expected.to eql('assignee')
      end

      context 'foreign keys' do
        let(:attribute_name) { :assigned_to_id }

        it 'sanitizes id-suffix before replacement lookup' do
          is_expected.to eql('assignee')
        end
      end
    end
  end
end
