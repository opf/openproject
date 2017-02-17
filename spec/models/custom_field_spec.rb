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

      describe 'WHEN value and type are identical and locale is different' do
        before do
          I18n.locale = :de
          field2.name = 'taken_name'

          # this fields needs an explicit english translations
          # otherwise it falls back using the german one
          I18n.locale = :en
          field2.name = 'unique_name'

          field2.save!

          field.name = 'taken_name'
        end

        it { expect(field).to be_valid }
      end
    end

    describe 'localization' do
      before do
        I18n.locale = :de
        field.name = 'Feld'

        I18n.locale = :en
        field.name = 'Field'
      end

      after do
        I18n.locale = :en
      end

      it 'should return english name when in locale en' do
        I18n.locale = :en
        expect(field.name).to eq('Field')
      end

      it 'should return german name when in locale de' do
        I18n.locale = :de
        expect(field.name).to eq('Feld')
      end
    end
  end

  describe '#translations_attributes' do
    describe 'WHEN providing a hash with locale and values' do
      before do
        field.translations_attributes = [{ 'name' => 'Feld',
                                           'locale' => 'de' }]
      end

      it { expect(field.translations.size).to eq(1) }
      it { expect(field.name(:de)).to eq('Feld') }
    end

    describe 'WHEN providing a hash with only a locale' do
      before do
        field.translations_attributes = [{ 'locale' => 'de' }]
      end

      it { expect(field.translations.size).to eq(0) }
    end

    describe 'WHEN providing a hash with a locale and blank values' do
      before do
        field.translations_attributes = [{ 'name' => '',
                                           'locale' => 'de' }]
      end

      it { expect(field.translations.size).to eq(0) }
    end

    describe 'WHEN providing a hash with a locale and only one values' do
      before do
        field.translations_attributes = [{ 'name' => 'Feld',
                                           'locale' => 'de' }]
      end

      it { expect(field.translations.size).to eq(1) }
      it { expect(field.name(:de)).to eq('Feld') }
    end

    describe 'WHEN providing a hash without a locale but with values' do
      before do
        field.translations_attributes = [{ 'name' => 'Feld',
                                           'locale' => '' }]
      end

      it { expect(field.translations.size).to eq(0) }
    end

    describe 'WHEN already having a translation and wishing to delete it' do
      before do
        I18n.locale = :de
        field.name = 'Feld'

        I18n.locale = :en
        field.name = 'Field'

        field.save!
        field.reload

        field.translations_attributes = [{ 'id' => field.translations.first.id.to_s,
                                           '_destroy' => '1' }]

        field.save!
      end

      it { expect(field.translations.size).to eq(1) }
    end
  end

  describe '#valid?' do
    describe "WITH a list field
              WITH two translations
              WITH default_value not included in possible_values in the non current locale translation" do

      before { skip("skip until replaced") }

      before do
        field.field_format = 'list'
        field.translations_attributes = [{ 'name' => 'Feld',
                                           'default_value' => 'vier',
                                           'possible_values' => ['eins', 'zwei', 'drei'],
                                           'locale' => 'de' },
                                         { 'name' => 'Field',
                                           'locale' => 'en',
                                           'possible_values' => "one\ntwo\nthree\n",
                                           'default_value' => 'two' }]
      end

      it { expect(field).not_to be_valid }
    end

    describe "WITH a list field
              WITH two translations
              WITH default_value included in possible_values" do

      before { skip("skip until replaced") }

      before do
        field.field_format = 'list'
        field.translations_attributes = [{ 'name' => 'Feld',
                                           'default_value' => 'zwei',
                                           'possible_values' => ['eins', 'zwei', 'drei'],
                                           'locale' => 'de' },
                                         { 'name' => 'Field',
                                           'locale' => 'en',
                                           'possible_values' => "one\ntwo\nthree\n",
                                           'default_value' => 'two' }]
      end

      it { expect(field).to be_valid }
    end

    describe "WITH a list field
              WITH two translations
              WITH default_value not included in possible_values in the current locale translation" do

      before { skip("skip until replaced") }

      before do
        field.field_format = 'list'
        field.translations_attributes = [{ 'name' => 'Feld',
                                           'default_value' => 'zwei',
                                           'possible_values' => ['eins', 'zwei', 'drei'],
                                           'locale' => 'de' },
                                         { 'name' => 'Field',
                                           'locale' => 'en',
                                           'possible_values' => "one\ntwo\nthree\n",
                                           'default_value' => 'four' }]
      end

      it { expect(field).not_to be_valid }
    end

    describe "WITH a list field
              WITH two translations
              WITH possible_values being empty in a fallbacked translation" do

      before { skip("skip until replaced") }

      before do
        field.field_format = 'list'
        field.translations_attributes = [{ 'name' => 'Feld',
                                           'locale' => 'de' },
                                         { 'name' => 'Field',
                                           'locale' => 'en',
                                           'possible_values' => "one\ntwo\nthree\n",
                                           'default_value' => 'two' }]
      end

      it { expect(field).to be_valid }
    end

    describe "WITH a list field
              WITH the field being required
              WITH two translations
              WITH neither translation defining a default_value" do

      before { skip("skip until replaced") }

      before do
        field.field_format = 'list'
        field.is_required = true
        field.translations_attributes = [{ 'name' => 'Feld',
                                           'locale' => 'de' },
                                         { 'name' => 'Field',
                                           'possible_values' => "one\ntwo\nthree\n",
                                           'locale' => 'en' }]
      end

      it { expect(field).to be_valid }
    end

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
