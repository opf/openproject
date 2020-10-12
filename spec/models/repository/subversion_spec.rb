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

describe Repository::Subversion, type: :model do
  let(:instance) { FactoryBot.build(:repository_subversion) }
  let(:adapter)  { instance.scm }
  let(:config)   { {} }
  let(:enabled_scm) { %w[subversion] }

  before do
    allow(Setting).to receive(:enabled_scm).and_return(enabled_scm)
    allow(instance).to receive(:scm).and_return(adapter)
    allow(instance.class).to receive(:scm_config).and_return(config)
  end

  describe 'when disabled' do
    let(:enabled_scm) { [] }

    it 'does not allow creating a repository' do
      expect { instance.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'returns an error when trying to save' do
      expect(instance.save).to eq false
      expect(instance.errors[:type]).to include I18n.translate('activerecord.errors.models.repository.not_available')
    end
  end

  describe 'default Subversion' do
    it 'is not manageable' do
      expect(instance.manageable?).to be false
    end

    it 'has one available type' do
      expect(instance.class.available_types).to eq [:existing]
    end

    context 'with disabled types' do
      let(:config) { { disabled_types: [:existing, :managed] } }

      it 'does not have any types' do
        expect(instance.class.available_types).to be_empty
      end
    end

    context 'with mixed disabled types' do
      let(:config) { { disabled_types: ['existing', :managed] } }

      it 'does not have any types' do
        expect(instance.class.available_types).to be_empty
      end
    end

    context 'with string disabled types' do
      before do
        allow(OpenProject::Configuration).to receive(:default_override_source)
          .and_return('OPENPROJECT_SCM_SUBVERSION_DISABLED__TYPES' => '[managed,unknowntype]')

        OpenProject::Configuration.load
        allow(instance.class).to receive(:scm_config).and_call_original
      end

      it 'is no longer manageable' do
        expect(instance.class.available_types).to eq([:existing])
        expect(instance.class.disabled_types).to eq([:managed, :unknowntype])
        expect(instance.manageable?).to be false
      end
    end
  end

  describe 'managed Subversion' do
    let(:managed_path) { '/tmp/managed_svn' }
    it 'is not manageable unless configured explicitly' do
      expect(instance.manageable?).to be false
    end

    context 'with managed config' do
      let(:config) { { manages: managed_path } }
      let(:project) { FactoryBot.build :project }

      it 'is manageable' do
        expect(instance.manageable?).to be true
        expect(instance.class.available_types).to eq([:existing, :managed])
      end

      context 'with disabled managed typed' do
        let(:config) { { disabled_types: [:managed] } }

        it 'is no longer manageable' do
          expect(instance.class.available_types).to eq([:existing])
          expect(instance.manageable?).to be false
        end
      end

      context 'and associated project' do
        before do
          instance.project = project
        end

        it 'outputs valid managed paths' do
          path = File.join(managed_path, project.identifier)
          expect(instance.managed_repository_path).to eq(path)
          expect(instance.managed_repository_url).to eq("file://#{path}")
        end
      end

      context 'and associated project with parent' do
        let(:parent) { FactoryBot.build :project }
        let(:project) { FactoryBot.build :project, parent: parent }

        before do
          instance.project = project
        end

        it 'outputs the correct hierarchy path' do
          expect(instance.managed_repository_path)
            .to eq(File.join(managed_path, project.identifier))
        end
      end
    end
  end

  describe 'with a remote repository' do
    let(:instance) {
      FactoryBot.build(:repository_subversion,
                        url: 'https://somewhere.example.org/svn/foo'
                       )
    }

    it_behaves_like 'is not a countable repository' do
      let(:repository) { instance }
    end
  end

  describe 'with an actual repository' do
    with_subversion_repository do |repo_dir|
      let(:url)      { "file://#{repo_dir}" }
      let(:instance) { FactoryBot.create(:repository_subversion, url: url, root_url: url) }

      it 'should be available' do
        expect(instance.scm).to be_available
      end

      it 'should fetch changesets from scratch' do
        instance.fetch_changesets
        instance.reload

        expect(instance.changesets.count).to eq(14)
        expect(instance.file_changes.count).to eq(34)
        expect(instance.changesets.find_by(revision: '1').comments).to eq('Initial import.')
      end

      it 'should fetch changesets incremental' do
        instance.fetch_changesets

        # Remove changesets with revision > 5
        instance.changesets.each do |c| c.destroy if c.revision.to_i > 5 end
        instance.reload
        expect(instance.changesets.count).to eq(5)

        instance.fetch_changesets
        expect(instance.changesets.count).to eq(14)
      end

      it 'should latest changesets' do
        instance.fetch_changesets

        # with limit
        changesets = instance.latest_changesets('', nil, 2)
        assert_equal 2, changesets.size
        assert_equal instance.latest_changesets('', nil).to_a.slice(0, 2), changesets

        # with path
        changesets = instance.latest_changesets('subversion_test/folder', nil)
        expect(changesets.map(&:revision)).to eq %w[10 9 7 6 5 2]

        # with path and revision
        changesets = instance.latest_changesets('subversion_test/folder', 8)
        expect(changesets.map(&:revision)).to eq %w[7 6 5 2]
      end

      it 'should directory listing with square brackets in path' do
        instance.fetch_changesets
        instance.reload

        entries = instance.entries('subversion_test/[folder_with_brackets]')
        expect(entries).to_not be_nil
        expect(entries.size).to eq(1)
        expect(entries.first.name).to eq('README.txt')
      end

      context 'with square brackets in base' do
        let(:url) { "file://#{repo_dir}/subversion_test/[folder_with_brackets]" }

        it 'should directory listing with square brackets in base' do
          instance.fetch_changesets
          instance.reload

          expect(instance.changesets.count).to eq(1)
          expect(instance.file_changes.count).to eq(2)

          entries = instance.entries('')
          expect(entries).to_not be_nil
          expect(entries.size).to eq(1)
          expect(entries.first.name).to eq('README.txt')
        end
      end

      it 'should show the identifier' do
        instance.fetch_changesets
        instance.reload
        c = instance.changesets.find_by(revision: '1')
        expect(c.revision).to eq(c.identifier)
      end

      it 'should find changeset by empty name' do
        instance.fetch_changesets
        instance.reload
        ['', ' ', nil].each do |r|
          expect(instance.find_changeset_by_name(r)).to be_nil
        end
      end

      it 'should identifier nine digit' do
        c = Changeset.new(repository: instance, committed_on: Time.now,
                          revision: '123456789', comments: 'test')
        expect(c.identifier).to eq(c.revision)
      end

      it 'should format identifier' do
        instance.fetch_changesets
        instance.reload
        c = instance.changesets.find_by(revision: '1')
        expect(c.format_identifier).to eq(c.revision)
      end

      it 'should format identifier nine digit' do
        c = Changeset.new(repository: instance, committed_on: Time.now,
                          revision: '123456789', comments: 'test')
        expect(c.format_identifier).to eq(c.revision)
      end

      context 'with windows-1252 encoding',
              with_settings: { commit_logs_encoding: %w(windows-1252) } do
        it 'should log encoding ignore setting' do
          s1 = "\xC2\x80"
          s2 = "\xc3\x82\xc2\x80"
          if s1.respond_to?(:force_encoding)
            s1.force_encoding('ISO-8859-1')
            s2.force_encoding('UTF-8')
            assert_equal s1.encode('UTF-8'), s2
          end
          c = Changeset.new(repository: instance,
                            comments:   s2,
                            revision:   '123',
                            committed_on: Time.now)
          expect(c.save).to be true
          expect(c.comments).to eq(s2)
        end
      end

      it 'should load previous and next changeset' do
        instance.fetch_changesets
        instance.reload
        changeset2 = instance.find_changeset_by_name('2')
        changeset3 = instance.find_changeset_by_name('3')
        expect(changeset3.previous).to eq(changeset2)
        expect(changeset2.next).to eq(changeset3)
      end

      it 'should return nil for no previous or next changeset' do
        instance.fetch_changesets
        instance.reload
        changeset = instance.find_changeset_by_name('1')
        expect(changeset.previous).to be_nil

        changeset = instance.find_changeset_by_name('14')
        expect(changeset.next).to be_nil
      end

      context 'with an admin browsing activity' do
        let(:user) { FactoryBot.create(:admin) }
        let(:project) { FactoryBot.create(:project) }

        def find_events(user, options = {})
          options[:scope] = ['changesets']
          fetcher = Activities::Fetcher.new(user, options)
          fetcher.events(Date.today - 30, Date.today + 1)
        end

        it 'should find events' do
          Changeset.create(repository: instance, committed_on: Time.now,
                           revision: '1', comments: 'test')
          event = find_events(user).first
          expect(event.event_title).to include('1:')
          expect(event.event_path).to match(/\?rev=1$/)
        end

        it 'should find events with larger numbers' do
          Changeset.create(repository: instance, committed_on: Time.now,
                           revision: '123456789', comments: 'test')
          event = find_events(user).first
          expect(event.event_title).to include('123456789:')
          expect(event.event_path).to match(/\?rev=123456789$/)
        end
      end

      describe "#entries" do
        let(:entries) { instance.entries }

        it "lists 10 entries" do
          expect(entries.size).to eq 10
        end

        describe "with limit: 5" do
          let(:directories) { entries.select { |e| e.kind == "dir" } }
          let(:files) { entries.select { |e| e.kind == "file" } }

          let(:limited_entries) { instance.entries limit: 5 }

          before do
            expect(directories.size).to eq 3
          end

          it "lists 5 entries only, directories first" do
            expected_entries = (directories + files.take(2)).map(&:path)

            expect(limited_entries.map(&:path)).to eq expected_entries
          end

          it "indicates 5 omitted entries" do
            expect(limited_entries.truncated).to eq 5
          end
        end
      end

      it_behaves_like 'is a countable repository' do
        let(:repository) { instance }
      end
    end
  end

  it_behaves_like 'repository can be relocated', :subversion

  describe 'ciphering' do
    it 'password is encrypted' do
      OpenProject::Configuration.with 'database_cipher_key' => 'secret' do
        r = FactoryBot.create(:repository_subversion, password: 'foo')
        expect(r.password)
          .to eql('foo')

        expect(r.read_attribute(:password))
          .to match(/\Aaes-256-cbc:.+\Z/)
      end
    end

    it 'password is unencrypted with blank key' do
      OpenProject::Configuration.with 'database_cipher_key' => '' do
        r = FactoryBot.create(:repository_subversion, password: 'foo')
        expect(r.password)
          .to eql('foo')
        expect(r.read_attribute(:password))
          .to eql('foo')
      end
    end

    it 'password is unencrypted with nil key' do
      OpenProject::Configuration.with 'database_cipher_key' => nil do
        r = FactoryBot.create(:repository_subversion, password: 'foo')

        expect(r.password)
          .to eql('foo')
        expect(r.read_attribute(:password))
          .to eql('foo')
      end
    end

    it 'unciphered password is readable if activating cipher later' do
      OpenProject::Configuration.with 'database_cipher_key' => nil do
        FactoryBot.create(:repository_subversion, password: 'clear')
      end

      OpenProject::Configuration.with 'database_cipher_key' => 'secret' do
        r = Repository.last

        expect(r.password)
          .to eql('clear')
      end
    end

    context '#encrypt_all' do
      it 'encrypts formerly unencrypted passwords' do
        Repository.delete_all
        OpenProject::Configuration.with 'database_cipher_key' => nil do
          FactoryBot.create(:repository_subversion, password: 'foo')
          FactoryBot.create(:repository_subversion, password: 'bar')
        end

        OpenProject::Configuration.with 'database_cipher_key' => 'secret' do
          expect(Repository.encrypt_all(:password))
            .to be_truthy

          bar = Repository.last

          expect(bar.password)
            .to eql('bar')
          expect(bar.read_attribute(:password))
            .to match(/\Aaes-256-cbc:.+\Z/)

          foo = Repository.first

          expect(foo.password)
            .to eql('foo')
          expect(foo.read_attribute(:password))
            .to match(/\Aaes-256-cbc:.+\Z/)
        end
      end
    end

    context '#decrypt_all' do
      it 'removes cyphering from all passwords' do
        Repository.delete_all
        OpenProject::Configuration.with 'database_cipher_key' => 'secret' do
          foo = FactoryBot.create(:repository_subversion, password: 'foo')
          bar = FactoryBot.create(:repository_subversion, password: 'bar')

          expect(Repository.decrypt_all(:password))
            .to be_truthy

          bar.reload

          expect(bar.password)
            .to eql('bar')
          expect(bar.read_attribute(:password))
            .to eql('bar')

          foo.reload

          expect(foo.password)
            .to eql('foo')
          expect(foo.read_attribute(:password))
            .to eql('foo')
        end
      end
    end
  end
end
