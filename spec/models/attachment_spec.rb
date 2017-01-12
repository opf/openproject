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

describe Attachment, type: :model do
  let(:author)           { FactoryGirl.create :user }
  let(:long_description) { 'a' * 300 }
  let(:work_package)     { FactoryGirl.create :work_package, description: '' }
  let(:file)             { FactoryGirl.create :uploaded_jpg, name: 'test.jpg' }

  let(:attachment) do
    FactoryGirl.build(
      :attachment,
      author:       author,
      container:    work_package,
      content_type: nil, # so that it is detected
      file:         file)
  end

  describe 'create' do
    context 'save' do
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

    it('should create a jpg file called test') do
      expect(File.exists?(attachment.diskfile.path)).to eq true
    end

    it('have the content type "image/jpeg"') do
      expect(attachment.content_type).to eq 'image/jpeg'
    end

    context 'with wrong content-type' do
      let(:file) { FactoryGirl.create :uploaded_jpg, content_type: 'text/html' }

      it 'should detect the correct content-type' do
        expect(attachment.content_type).to eq 'image/jpeg'
      end
    end
  end

  describe 'update' do
    before do
      attachment.save!
    end

    context 'update' do
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

  ##
  # The tests assumes the default, file-based storage is configured and tests against that.
  # I.e. it does not test fog attachments being deleted from the cloud storage (such as S3).
  describe 'destroy' do
    before do
      attachment.save!

      expect(File.exists?(attachment.file.path)).to eq true

      attachment.destroy
      attachment.run_callbacks(:commit)
      # triggering after_commit callbacks manually as they are not triggered during rspec runs
      # though in dev/production mode destroy does trigger these callbacks
    end

    it "deletes the attachment's file" do
      expect(File.exists?(attachment.file.path)).to eq false
    end
  end
end
