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

describe AttributeHelpText::WorkPackage, type: :model do
  describe '.available_attributes' do
    subject { described_class.available_attributes }
    it 'returns an array of potential attributes' do
      expect(subject).to be_a Hash
    end
  end

  describe '.used_attributes' do
    let!(:instance) { FactoryGirl.create :work_package_help_text }
    subject { described_class.used_attributes instance.type }

    it 'returns used attributes' do
      expect(subject).to eq([instance.attribute_name])
    end
  end

  describe 'validations' do
    before do
      allow(described_class).to receive(:available_attributes).and_return(status: 'Status')
    end

    let(:attribute_name) { 'status' }
    let(:help_text) { 'foobar' }

    subject { described_class.new attribute_name: attribute_name, help_text: help_text }

    context 'help_text is nil' do
      let(:help_text) { nil }

      it 'validates presence of help text' do
        expect(subject.valid?).to be_falsey
        expect(subject.errors[:help_text].count).to eql(1)
        expect(subject.errors[:help_text].first)
          .to eql(I18n.t('activerecord.errors.messages.blank'))
      end
    end

    context 'attribute_name is nil' do
      let(:attribute_name) { nil }

      it 'validates presence of attribute name' do
        expect(subject.valid?).to be_falsey
        expect(subject.errors[:attribute_name].count).to eql(1)
        expect(subject.errors[:attribute_name].first)
          .to eql(I18n.t('activerecord.errors.messages.inclusion'))
      end
    end

    context 'attribute_name is invalid' do
      let(:attribute_name) { 'foobar' }

      it 'validates inclusion of attribute name' do
        expect(subject.valid?).to be_falsey
        expect(subject.errors[:attribute_name].count).to eql(1)
        expect(subject.errors[:attribute_name].first)
          .to eql(I18n.t('activerecord.errors.messages.inclusion'))
      end
    end
  end

  describe 'instance' do
    subject { FactoryGirl.build :work_package_help_text }

    it 'provides a caption of its type' do
      expect(subject.attribute_scope).to eq 'WorkPackage'
      expect(subject.type_caption).to eq I18n.t(:label_work_package)
    end
  end
end
