#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require_relative '../spec_helper'

RSpec.describe Storages::NextcloudStorage do
  let(:storage) { build(:storage) }

  shared_examples 'a stored attribute with default value' do |attribute, default_value|
    it "has a default value of #{default_value}" do
      expect(storage.public_send(attribute)).to eq(default_value)
    end

    context "with a value of 'foo'" do
      it "sets the value to 'foo'" do
        storage.public_send("#{attribute}=", 'foo')
        expect(storage.public_send(attribute)).to eq('foo')
      end
    end
  end

  shared_examples 'a stored boolean attribute' do |attribute|
    it "#{attribute} has a default value of false" do
      expect(storage.public_send(:"#{attribute}?")).to be(false)
    end

    ['1', 'true', true].each do |boolean_like|
      context "with truthy value #{boolean_like}" do
        it "sets #{attribute} to true" do
          storage.public_send(:"#{attribute}=", boolean_like)
          expect(storage.public_send(attribute)).to be(true)
        end
      end
    end

    it "#{attribute} can be set to true" do
      storage.public_send(:"#{attribute}=", true)

      expect(storage.public_send(attribute)).to be(true)
      expect(storage.public_send(:"#{attribute}?")).to be(true)
    end
  end

  describe '#username' do
    it_behaves_like 'a stored attribute with default value', :username, 'OpenProject'
  end

  describe '#group' do
    it_behaves_like 'a stored attribute with default value', :group, 'OpenProject'
  end

  describe '#group_folder' do
    it_behaves_like 'a stored attribute with default value', :group_folder, 'OpenProject'
  end

  describe '#automatically_managed?' do
    it_behaves_like 'a stored boolean attribute', :automatically_managed
  end

  describe '#has_managed_project_folders?' do
    it_behaves_like 'a stored boolean attribute', :has_managed_project_folders
  end

  describe '#automatic_management_unspecified?' do
    context 'when automatically_managed is nil' do
      let(:storage) { build(:storage, automatically_managed: nil) }

      it { expect(storage).to be_automatic_management_unspecified }
    end

    context 'when automatically_managed is true' do
      let(:storage) { build(:storage, automatically_managed: true) }

      it { expect(storage).not_to be_automatic_management_unspecified }
    end

    context 'when automatically_managed is false' do
      let(:storage) { build(:storage, automatically_managed: false) }

      it { expect(storage).not_to be_automatic_management_unspecified }
    end
  end

  describe '#provider_fields_defaults' do
    let(:storage) { build(:storage) }

    it 'returns the default values for nextcloud' do
      expect(storage.provider_fields_defaults).to eq(
        { automatically_managed: true, username: 'OpenProject' }
      )
    end
  end
end
