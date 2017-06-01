#-- encoding: UTF-8
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

require 'spec_helper'

describe Scm::CheckoutInstructionsService do
  let(:user) { FactoryGirl.build(:user) }
  let(:project) { FactoryGirl.build(:project) }

  let(:url) { 'file:///tmp/some/svn/repo' }
  let(:repository) {
    FactoryGirl.build(:repository_subversion,
                      url: url,
                      project: project)
  }

  let(:base_url) { 'http://example.org/svn/' }
  let(:path) { nil }
  let(:text) { 'foo' }
  let(:checkout_hash) {
    {
      'git' => { 'enabled' => '0' },
      'subversion' => { 'enabled' => '1',
                        'text' => text,
                        'base_url' => base_url
                      }
    }
  }

  subject(:service) { Scm::CheckoutInstructionsService.new(repository, user: user, path: path) }

  before do
    allow(Setting).to receive(:repository_checkout_data).and_return(checkout_hash)
  end

  describe '#checkout_url' do
    shared_examples 'builds the correct URL' do
      it 'builds the correct URL' do
        expect(service.checkout_url)
          .to eq(URI("http://example.org/svn/#{project.identifier}"))
      end

      shared_examples 'valid checkout URL' do
        it do
          expect(service.checkout_url(path))
            .to eq(URI("http://example.org/svn/#{project.identifier}/#{expected_path}"))
        end
      end

      it_behaves_like 'valid checkout URL' do
        let(:path) { 'foo/bar' }
        let(:expected_path) { path }
      end

      it_behaves_like 'valid checkout URL' do
        let(:path) { 'foo/bar with spaces' }
        let(:expected_path) { 'foo/bar%20with%20spaces' }
      end

      it_behaves_like 'valid checkout URL' do
        let(:path) { 'foo/bar with §\"!??```' }
        let(:expected_path) { 'foo/%C2%A7%22!??%60%60%60' }
      end
    end
  end

  describe '#checkout_command' do
    it 'returns the SCM vendor command' do
      expect(service.checkout_command).to eq('svn checkout')
    end
  end

  describe '#instructions' do
    it 'returns the setting when defined' do
      expect(service.instructions).to eq('foo')
    end

    context 'no setting defined' do
      let(:text) { nil }

      it 'returns the default translated instructions' do
        expect(service.instructions)
          .to eq(I18n.t('repositories.checkout.default_instructions.subversion'))
      end
    end
  end

  describe '#settings' do
    it 'svn is available for checkout' do
      expect(service.available?).to be true
      expect(service.checkout_enabled?).to be true
    end

    it 'has the correct settings' do
      expect(Setting.repository_checkout_data['subversion']['enabled']).to eq('1')
      expect(service.instructions).to eq('foo')
      expect(service.checkout_base_url).to eq(base_url)
    end

    context 'missing checkout base URL' do
      let(:base_url) { '' }

      it 'is not available for checkout even when enabled' do
        expect(service.checkout_base_url).to eq(base_url)
        expect(service.checkout_enabled?).to be true
        expect(service.available?).to be false
      end
    end

    context 'disabled repository' do
      let(:repository) { FactoryGirl.build(:repository_git) }

      it 'git is not available for checkout' do
        expect(service.available?).to be false
        expect(service.checkout_enabled?).to be false
      end
    end
  end

  describe '#permission' do
    context 'with no managed repository' do
      it 'is not applicable' do
        expect(service.manages_permissions?).to be false
      end
    end

    context 'with managed repository' do
      before do
        allow(repository).to receive(:managed?).and_return(true)
      end

      it 'is applicable' do
        expect(service.manages_permissions?).to be true
      end

      it 'returns the correct permissions' do
        expect(user)
          .to receive(:allowed_to?).with(:commit_access, any_args)
          .and_return(true, false, false)

        expect(user)
          .to receive(:allowed_to?).with(:browse_repository, any_args)
          .and_return(true, false)

        expect(service.permission).to eq(:readwrite)
        expect(service.permission).to eq(:read)
        expect(service.permission).to eq(:none)
      end

      it 'returns the correct permissions for commit access' do
        allow(user)
          .to receive(:allowed_to?).with(:commit_access, any_args)
          .and_return(true)

        expect(service.may_commit?).to be true
        expect(service.may_checkout?).to be true
      end

      it 'returns the correct permissions for read access' do
        allow(user)
          .to receive(:allowed_to?).with(:commit_access, any_args)
          .and_return(false)
        allow(user)
          .to receive(:allowed_to?).with(:browse_repository, any_args)
          .and_return(true)

        expect(service.may_commit?).to be false
        expect(service.may_checkout?).to be true
      end

      it 'returns the correct permissions for no access' do
        allow(user).to receive(:allowed_to?).and_return(false)

        expect(service.may_commit?).to be false
        expect(service.may_checkout?).to be false
      end
    end
  end
end
