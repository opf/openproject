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

describe CustomField, type: :model do
  before do CustomField.destroy_all end

  let(:field)  { FactoryGirl.build :custom_field }
  let(:field2) { FactoryGirl.build :custom_field }

  describe '#name' do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(30) }

    describe 'uniqueness' do
      describe 'WHEN value, locale and type are identical' do
        before do
          field.name = field2.name = 'taken name'
          field2.save!
        end

        it { expect(field).not_to be_valid }
      end

      describe 'WHEN value and locale are identical and type is different' do
        before do
          field.name = field2.name = 'taken name'
          field2.save!
          field.type = 'TestCustomField'
        end

        it { expect(field).to be_valid }
      end

      describe 'WHEN type and locale are identical and value is different' do
        before do
          field.name = 'new name'
          field2.name = 'taken name'
          field2.save!
        end

        it { expect(field).to be_valid }
      end
    end
  end

  describe '#valid?' do
    describe "WITH a text field
              WITH minimum length blank" do
      before do
        field.field_format = 'text'
        field.min_length = nil
      end
      it { expect(field).not_to be_valid }
    end

    describe "WITH a text field
              WITH maximum length blank" do
      before do
        field.field_format = 'text'
        field.max_length = nil
      end
      it { expect(field).not_to be_valid }
    end

    describe "WITH a text field
              WITH minimum length not an integer" do
      before do
        field.field_format = 'text'
        field.min_length = 'a'
      end
      it { expect(field).not_to be_valid }
    end

    describe "WITH a text field
              WITH maximum length not an integer" do
      before do
        field.field_format = 'text'
        field.max_length = 'a'
      end
      it { expect(field).not_to be_valid }
    end

    describe "WITH a text field
              WITH minimum length greater than maximum length" do
      before do
        field.field_format = 'text'
        field.min_length = 2
        field.max_length = 1
      end
      it { expect(field).not_to be_valid }
    end

    describe "WITH a text field
              WITH negative minimum length" do
      before do
        field.field_format = 'text'
        field.min_length = -2
      end
      it { expect(field).not_to be_valid }
    end

    describe "WITH a text field
              WITH negative maximum length" do
      before do
        field.field_format = 'text'
        field.max_length = -2
      end
      it { expect(field).not_to be_valid }
    end
  end

  describe '#accessor_name' do
    # create the custom field to force assignment of an id
    let(:field)  { FactoryGirl.create :custom_field }

    it 'is formatted as expected' do
      expect(field.accessor_name).to eql("custom_field_#{field.id}")
    end

    it 'returns a string' do
      expect(field.accessor_name).to be_a(String)
    end
  end
end
