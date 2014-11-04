#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

describe Attachment, type: :model do
  let(:author) { FactoryGirl.create(:user) }
  let(:long_description) { 'a' * 300 }
  let(:work_package) { FactoryGirl.create(:work_package, description: '') }
  let(:attachment) {
    FactoryGirl.build(:attachment,
                      author: author,
                      container: work_package,
                      filename: 'foo.jpg')
  }
  describe 'create' do
    context :save do
      before do
        attachment.description = long_description
        attachment.valid?
      end

      it 'should validate description length' do
        expect(attachment.errors[:description]).not_to be_empty
      end

      it 'should raise an error regarding description length' do
        expect(attachment.errors.full_messages[0]).to include I18n.t('activerecord.errors.messages.too_long', count: 255)
      end
    end
  end

  describe 'update' do
    let!(:attachment) {
      FactoryGirl.create(:attachment,
                         author: author,
                         container: work_package,
                         filename: 'foo.jpg')
    }
    context :update do
      before do
        attachment.description = long_description
        attachment.valid?
      end

      it 'should validate description length' do
        expect(attachment.errors[:description]).not_to be_empty
      end

      it 'should raise an error regarding description length' do
        expect(attachment.errors.full_messages[0]).to include I18n.t('activerecord.errors.messages.too_long', count: 255)
      end
    end
  end
end
