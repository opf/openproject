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

require 'spec_helper'

describe ::API::V3::Configuration::ConfigurationRepresenter do
  include ::API::V3::Utilities::PathHelper

  let(:represented) {
    double('Settings',
           attachment_max_size: '1024')
  }
  let(:current_user) { FactoryGirl.build_stubbed(:user) }
  let(:representer) { described_class.new(represented, current_user: current_user) }

  context 'generation' do
    subject { representer.to_json }

    describe '_links' do
      it_behaves_like 'has an untitled link' do
        let(:link) { 'self' }
        let(:href) { api_v3_paths.configuration }
      end
    end

    it 'indicates its type' do
      is_expected.to be_json_eql('Configuration'.to_json).at_path('_type')
    end

    it 'indicates maximumAttachmentFileSize in Bytes' do
      is_expected.to be_json_eql((1024 * 1024).to_json).at_path('maximumAttachmentFileSize')
    end
  end
end
