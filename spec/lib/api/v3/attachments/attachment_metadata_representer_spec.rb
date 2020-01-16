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

describe ::API::V3::Attachments::AttachmentMetadataRepresenter do
  include API::V3::Utilities::PathHelper

  let(:metadata) {
    data = Hashie::Mash.new
    data.file_name = original_file_name
    data.description = original_description
    data
  }
  let(:original_file_name) { 'a file name' }
  let(:original_description) { 'a description' }
  let(:representer) { ::API::V3::Attachments::AttachmentMetadataRepresenter.new(metadata) }

  describe 'generation' do
    subject { representer.to_json }

    it 'is a type-less representer' do
      is_expected.not_to have_json_path('_type')
    end

    it { is_expected.to be_json_eql(original_file_name.to_json).at_path('fileName') }

    it_behaves_like 'API V3 formattable', 'description' do
      let(:format) { 'plain' }
      let(:raw) { original_description }
    end
  end

  describe 'parsing' do
    let(:parsed_hash) {
      {
        'fileName' => 'the parsed name',
        'description' => { 'raw' => 'the parsed description' }
      }
    }

    subject { metadata }

    before do
      representer.from_hash parsed_hash
    end

    it { expect(subject.file_name).to eql('the parsed name') }
    it { expect(subject.description).to eql('the parsed description') }
  end
end
