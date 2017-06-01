#-- encoding: UTF-8
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

describe Scm::CreateLocalRepositoryJob do
  subject { described_class.new(repository) }

  # Allow to override configuration values to determine
  # whether to activate managed repositories
  let(:enabled_scms) { %w[subversion git] }
  let(:config) { nil }

  before do
    allow(Setting).to receive(:enabled_scm).and_return(enabled_scms)

    allow(OpenProject::Configuration).to receive(:[]).and_call_original
    allow(OpenProject::Configuration).to receive(:[]).with('scm').and_return(config)
  end

  describe 'with a managed repository' do
    include_context 'with tmpdir'

    let(:project) { FactoryGirl.build(:project) }
    let(:repository) {
      repo = Repository::Subversion.new(scm_type: :managed)
      repo.project = project
      repo.configure(:managed, nil)
      repo
    }

    let(:config) {
      { subversion: { mode: mode, manages: tmpdir } }
    }

    shared_examples 'creates a directory with mode' do |expected|
      it 'creates the directory' do
        subject.perform
        expect(Dir.exists?(repository.root_url)).to be true

        file_mode = File.stat(repository.root_url).mode
        expect(sprintf("%o", file_mode)).to end_with(expected)
      end
    end

    context 'with mode set' do
      let(:mode) { 0770 }

      it 'uses the correct mode' do
        expect(subject).to receive(:create).with(mode)
        subject.perform
      end

      it_behaves_like 'creates a directory with mode', '0770'
    end

    context 'with string mode' do
      let(:mode) { '0770' }
      it 'uses the correct mode' do
        expect(subject).to receive(:create).with(0770)
        subject.perform
      end

      it_behaves_like 'creates a directory with mode', '0770'
    end

    context 'with no mode set' do
      let(:mode) { nil }
      it 'uses the default mode' do
        expect(subject).to receive(:create).with(0700)
        subject.perform
      end

      it_behaves_like 'creates a directory with mode', '0700'
    end
  end
end
