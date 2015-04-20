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

describe Repository::Filesystem, type: :model do
  before do
    allow(Setting).to receive(:enabled_scm).and_return(['Filesystem'])
  end

  let(:instance) { described_class.new }

  def mock_dirs_exist(input, output)
    allow(Dir).to receive(:glob).with(input).and_return(output)
    allow(Dir).to receive(:exists?).with(input).and_return(true)
  end

  describe '.configured?' do
    subject { described_class.configured? }

    context 'configuration contains directories' do
      before do
        allow(OpenProject::Configuration)
          .to receive(:[])
          .with('scm_filesystem_path_whitelist')
          .and_return(['/dir'])
      end

      it 'is true' do
        is_expected.to be_truthy
      end
    end

    context 'configuration does not contain directories' do
      before do
        allow(OpenProject::Configuration)
          .to receive(:[])
          .with('scm_filesystem_path_whitelist')
          .and_return([])
      end

      it 'is false' do
        is_expected.to be_falsey
      end
    end
  end

  describe '#valid?' do
    let(:desired_url) { 'something' }
    let(:whitelisted_urls) { 'another_thing' }

    let(:valid_args) do
      { url: desired_url,
        path_encoding: 'US-ASCII' }
    end
    let(:expected_url_whitelist_error_message) do
      [I18n.t('activerecord.errors.models.repository.not_whitelisted')]
    end
    let(:expected_url_not_directory_error_message) do
      [I18n.t('activerecord.errors.models.repository.no_directory')]
    end

    before do
      mock_dirs_exist(desired_url, ['/this/will/match'])
      mock_dirs_exist(whitelisted_urls, ['/this/will/match'])

      allow(OpenProject::Configuration).to receive(:[])
                                       .with('scm_filesystem_path_whitelist')
                                       .and_return(whitelisted_urls)

      instance.attributes = valid_args
    end

    subject { instance }

    it 'is valid' do
      is_expected.to be_valid
    end

    context 'url not whitelisted' do
      before do
        mock_dirs_exist(desired_url, ['/desired/dir'])
        mock_dirs_exist(whitelisted_urls, ['/desired',
                                           '/desired/*',
                                           '/desired/di',
                                           '/desired/dir/1',
                                           '*'])
      end

      it 'is invalid' do
        instance.attributes = valid_args

        is_expected.to be_invalid
        expect(subject.errors[:url]).to eql(expected_url_whitelist_error_message)
      end
    end

    context 'url is not a directory' do
      before do
        allow(Dir).to receive(:exists?).with(desired_url).and_return(false)
      end

      it 'is invalid' do
        is_expected.to be_invalid
        expect(subject.errors[:url]).to eql(expected_url_not_directory_error_message)
      end
    end

    context 'url does not exist' do
      before do
        mock_dirs_exist(desired_url, [])
      end

      it 'is invalid' do
        is_expected.to be_invalid
        expect(subject.errors[:url]).to eql(expected_url_whitelist_error_message)
      end
    end

    context 'nothing is whitelisted' do
      before do
        mock_dirs_exist(whitelisted_urls, [])
      end

      it 'is invalid' do
        instance.attributes = valid_args

        is_expected.to be_invalid
        expect(subject.errors[:url]).to eql(expected_url_whitelist_error_message)
      end
    end
  end
end
