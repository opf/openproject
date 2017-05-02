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

describe Repository::Git, type: :model do
  let(:encoding) { 'UTF-8' }
  let(:instance) { FactoryGirl.build(:repository_git, path_encoding: encoding) }
  let(:adapter)  { instance.scm }
  let(:config)   { {} }
  let(:enabled_scm) { %w[git] }

  before do
    allow(Setting).to receive(:enabled_scm).and_return(enabled_scm)
    allow(instance).to receive(:scm).and_return(adapter)
    allow(adapter.class).to receive(:config).and_return(config)
  end

  describe 'when disabled' do
    let(:enabled_scm) { [] }

    it 'does not allow creating a repository' do
      expect { instance.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe 'available types' do
    it 'allow local by default' do
      expect(instance.class.available_types).to eq([:local])
    end

    context 'with disabled types' do
      let(:config) { { disabled_types: [:local, :managed] } }

      it 'does not have any types' do
        expect(instance.class.available_types).to be_empty
      end
    end

    context 'with mixed disabled types' do
      let(:config) { { disabled_types: [:local, 'managed'] } }

      it 'does not have any types' do
        expect(instance.class.available_types).to be_empty
      end
    end
  end

  describe 'managed git' do
    let(:managed_path) { '/tmp/managed_git' }
    it 'is not manageable unless configured explicitly' do
      expect(instance.manageable?).to be false
    end

    context 'with managed config' do
      let(:config) { { manages: managed_path } }
      let(:project) { FactoryGirl.build :project }
      let(:identifier) { project.identifier + '.git' }

      it 'is manageable' do
        expect(instance.manageable?).to be true
        expect(instance.class.available_types).to eq([:local, :managed])
      end

      context 'with disabled managed typed' do
        let(:config) { { disabled_types: [:managed] } }

        it 'is no longer manageable' do
          expect(instance.class.available_types).to eq([:local])
          expect(instance.manageable?).to be false
        end
      end

      context 'with string disabled types' do
        before do
          allow(OpenProject::Configuration).to receive(:default_override_source)
            .and_return('OPENPROJECT_SCM_GIT_DISABLED__TYPES' => '[managed,local]')

          OpenProject::Configuration.load
          allow(adapter.class).to receive(:config).and_call_original
        end

        it 'is no longer manageable' do
          expect(instance.class.available_types).to eq([])
          expect(instance.class.disabled_types).to eq([:managed, :local])
          expect(instance.manageable?).to be false
        end
      end

      context 'and associated project' do
        before do
          instance.project = project
        end

        it 'outputs valid managed paths' do
          expect(instance.repository_identifier).to eq(identifier)
          path = File.join(managed_path, identifier)
          expect(instance.managed_repository_path).to eq(path)
          expect(instance.managed_repository_url).to eq(path)
        end
      end

      context 'and associated project with parent' do
        let(:parent) { FactoryGirl.build :project }
        let(:project) { FactoryGirl.build :project, parent: parent }

        before do
          instance.project = project
        end

        it 'outputs the correct hierarchy path' do
          expect(instance.managed_repository_path)
            .to eq(File.join(managed_path, identifier))
        end
      end
    end
  end

  describe 'with an actual repository' do
    with_git_repository do |repo_dir|
      let(:url)      { repo_dir }
      let(:instance) {
        FactoryGirl.create(:repository_git,
                           path_encoding: encoding,
                           url: url,
                           root_url: url)
      }

      before do
        instance.fetch_changesets
        instance.reload
      end

      it 'should be available' do
        expect(instance.scm).to be_available
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

      it 'should fetch changesets from scratch' do
        expect(instance.changesets.count).to eq(22)
        expect(instance.file_changes.count).to eq(34)

        commit = instance.changesets.reorder('committed_on ASC').first
        expect(commit.comments).to eq("Initial import.\nThe repository contains 3 files.")
        expect(commit.committer).to eq('jsmith <jsmith@foo.bar>')
        # assert_equal User.find_by_login('jsmith'), commit.user
        # TODO: add a commit with commit time <> author time to the test repository
        expect(commit.committed_on).to eq('2007-12-14 09:22:52')
        expect(commit.commit_date).to eq('2007-12-14'.to_date)
        expect(commit.revision).to eq('7234cb2750b63f47bff735edc50a1c0a433c2518')
        expect(commit.scmid).to eq('7234cb2750b63f47bff735edc50a1c0a433c2518')
        expect(commit.file_changes.count).to eq(3)

        change = commit.file_changes.sort_by(&:path).first
        expect(change.path).to eq('README')
        expect(change.action).to eq('A')
      end

      it 'should fetch changesets incremental' do
        # Remove the 3 latest changesets
        instance.changesets.order('committed_on DESC').limit(8).each(&:destroy)
        instance.reload
        expect(instance.changesets.count).to eq(14)

        rev_a_commit = instance.changesets.order('committed_on DESC').first
        expect(rev_a_commit.revision).to eq('ed5bb786bbda2dee66a2d50faf51429dbc043a7b')
        expect(rev_a_commit.scmid).to eq('ed5bb786bbda2dee66a2d50faf51429dbc043a7b')
        # Mon Jul 5 22:34:26 2010 +0200
        committed_on = Time.gm(2010, 9, 18, 19, 59, 46)
        expect(rev_a_commit.committed_on).to eq(committed_on)
        expect(instance.latest_changeset.committed_on).to eq(committed_on)

        instance.fetch_changesets
        expect(instance.changesets.count).to eq(22)
      end

      describe '.latest_changesets' do
        it 'should fetch changesets with limits' do
          changesets = instance.latest_changesets('', nil, 2)
          expect(changesets.size).to eq(2)
        end

        it 'should fetch changesets with paths' do
          changesets = instance.latest_changesets('images', nil)
          expect(changesets.map(&:revision))
            .to eq(['deff712f05a90d96edbd70facc47d944be5897e3',
                    '899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
                    '7234cb2750b63f47bff735edc50a1c0a433c2518'])

          changesets = instance.latest_changesets('README', nil)
          expect(changesets.map(&:revision))
            .to eq(['32ae898b720c2f7eec2723d5bdd558b4cb2d3ddf',
                    '4a07fe31bffcf2888791f3e6cbc9c4545cefe3e8',
                    '713f4944648826f558cf548222f813dabe7cbb04',
                    '61b685fbe55ab05b5ac68402d5720c1a6ac973d1',
                    '899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
                    '7234cb2750b63f47bff735edc50a1c0a433c2518'])
        end

        it 'should fetch changesets with path, revision and limit' do
          changesets = instance.latest_changesets('images', '899a15dba')
          expect(changesets.map(&:revision))
            .to eq(['899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
                    '7234cb2750b63f47bff735edc50a1c0a433c2518'])

          changesets = instance.latest_changesets('images', '899a15dba', 1)
          expect(changesets.map(&:revision))
            .to eq(['899a15dba03a3b350b89c3f537e4bbe02a03cdc9'])

          changesets = instance.latest_changesets('README', '899a15dba')
          expect(changesets.map(&:revision))
            .to eq(['899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
                    '7234cb2750b63f47bff735edc50a1c0a433c2518'])

          changesets = instance.latest_changesets('README', '899a15dba', 1)
          expect(changesets.map(&:revision))
            .to eq(['899a15dba03a3b350b89c3f537e4bbe02a03cdc9'])
        end

        it 'should fetch changesets with tag' do
          changesets = instance.latest_changesets('images', 'tag01.annotated')
          expect(changesets.map(&:revision))
            .to eq(['899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
                    '7234cb2750b63f47bff735edc50a1c0a433c2518'])

          changesets = instance.latest_changesets('README', '899a15dba', 1)
          expect(changesets.map(&:revision))
            .to eq(['899a15dba03a3b350b89c3f537e4bbe02a03cdc9'])

          changesets = instance.latest_changesets('README', 'tag01.annotated')
          expect(changesets.map(&:revision))
            .to eq(['899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
                    '7234cb2750b63f47bff735edc50a1c0a433c2518'])

          changesets = instance.latest_changesets('README', 'tag01.annotated', 1)
          expect(changesets.map(&:revision))
            .to eq(['899a15dba03a3b350b89c3f537e4bbe02a03cdc9'])
        end

        it 'should fetch changesets with path, branch, and limit' do
          changesets = instance.latest_changesets('images', 'test_branch')
          expect(changesets.map(&:revision))
            .to eq(['899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
                    '7234cb2750b63f47bff735edc50a1c0a433c2518'])

          changesets = instance.latest_changesets('images', 'test_branch', 1)
          expect(changesets.map(&:revision))
            .to eq(['899a15dba03a3b350b89c3f537e4bbe02a03cdc9'])

          changesets = instance.latest_changesets('README', 'test_branch')
          expect(changesets.map(&:revision))
            .to eq(['713f4944648826f558cf548222f813dabe7cbb04',
                    '61b685fbe55ab05b5ac68402d5720c1a6ac973d1',
                    '899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
                    '7234cb2750b63f47bff735edc50a1c0a433c2518'])

          changesets = instance.latest_changesets('README', 'test_branch', 2)
          expect(changesets.map(&:revision))
            .to eq(['713f4944648826f558cf548222f813dabe7cbb04',
                    '61b685fbe55ab05b5ac68402d5720c1a6ac973d1'])
        end
      end

      it 'should find changeset by name' do
        ['7234cb2750b63f47bff735edc50a1c0a433c2518', '7234cb2750b'].each do |r|
          expect(instance.find_changeset_by_name(r).revision)
            .to eq('7234cb2750b63f47bff735edc50a1c0a433c2518')
        end
      end

      it 'should find changeset by empty name' do
        ['', ' ', nil].each do |r|
          expect(instance.find_changeset_by_name(r)).to be_nil
        end
      end

      it 'should assign scmid to identifier' do
        c = instance.changesets.where(revision: '7234cb2750b63f47bff735edc50a1c0a433c2518').first
        expect(c.scmid).to eq(c.identifier)
      end

      it 'should format identifier' do
        c = instance.changesets.where(revision: '7234cb2750b63f47bff735edc50a1c0a433c2518').first
        expect(c.format_identifier).to eq('7234cb27')
      end

      it 'should find previous changeset' do
        %w|1ca7f5ed374f3cb31a93ae5215c2e25cc6ec5127 1ca7f5ed|.each do |r1|
          changeset = instance.find_changeset_by_name(r1)
          %w|64f1f3e89ad1cb57976ff0ad99a107012ba3481d 64f1f3e89ad1|.each do |r2|
            expect(instance.find_changeset_by_name(r2)).to eq(changeset.previous)
          end
        end
      end

      it 'should return nil when no previous changeset' do
        %w|7234cb2750b63f47bff735edc50a1c0a433c2518 7234cb2|.each do |r1|
          changeset = instance.find_changeset_by_name(r1)
          expect(changeset.previous).to be_nil
        end
      end

      it 'should find next changeset' do
        %w|64f1f3e89ad1cb57976ff0ad99a107012ba3481d 64f1f3e89ad1|.each do |r2|
          changeset = instance.find_changeset_by_name(r2)
          %w|1ca7f5ed374f3cb31a93ae5215c2e25cc6ec5127 1ca7f5ed|.each do |r1|
            expect(instance.find_changeset_by_name(r1)).to eq(changeset.next)
          end
        end
      end

      it 'should next nil' do
        %w|71e5c1d3dca6304805b143b9d0e6695fb3895ea4 71e5c1d3|.each do |r1|
          changeset = instance.find_changeset_by_name(r1)
          expect(changeset.next).to be_nil
        end
      end

      context 'with an admin browsing activity' do
        let(:user) { FactoryGirl.create(:admin) }
        let(:project) { FactoryGirl.create(:project) }

        def find_events(user, options = {})
          fetcher = Redmine::Activity::Fetcher.new(user, options)
          fetcher.scope = ['changesets']
          fetcher.events(Date.today - 30, Date.today + 1)
        end

        it 'should activities' do
          Changeset.create(repository: instance,
                           committed_on: Time.now,
                           revision: 'abc7234cb2750b63f47bff735edc50a1c0a433c2',
                           scmid:    'abc7234cb2750b63f47bff735edc50a1c0a433c2',
                           comments: 'test')

          event = find_events(user).first
          assert event.event_title.include?('abc7234c:')
          assert event.event_path =~ /\?rev=abc7234cb2750b63f47bff735edc50a1c0a433c2$/
        end
      end

      describe 'encoding' do
        let(:felix_hex) { "Felix Sch\xC3\xA4fer" }

        it 'should display UTF-8' do
          c = instance.changesets.where(revision: 'ed5bb786bbda2dee66a2d50faf51429dbc043a7b').first
          expect(c.committer).to eq("#{felix_hex} <felix@fachschaften.org>")
          expect(c.committer).to eq('Felix Schäfer <felix@fachschaften.org>')
        end

        context 'with latin-1 encoding' do
          let (:encoding) { 'ISO-8859-1' }
          let (:char1_hex) { "\xc3\x9c".force_encoding('UTF-8') }

          it 'should latest changesets latin 1 dir' do
            instance.fetch_changesets
            instance.reload
            changesets = instance.latest_changesets(
              "latin-1-dir/test-#{char1_hex}-subdir", '1ca7f5ed')
            expect(changesets.map(&:revision))
              .to eq(['1ca7f5ed374f3cb31a93ae5215c2e25cc6ec5127'])
          end

          it 'should browse changesets' do
            changesets = instance.latest_changesets(
              "latin-1-dir/test-#{char1_hex}-2.txt", '64f1f3e89')
            expect(changesets.map(&:revision))
              .to eq(['64f1f3e89ad1cb57976ff0ad99a107012ba3481d',
                      '4fc55c43bf3d3dc2efb66145365ddc17639ce81e',
                     ])

            changesets = instance.latest_changesets(
              "latin-1-dir/test-#{char1_hex}-2.txt", '64f1f3e89', 1)
            expect(changesets.map(&:revision))
              .to eq(['64f1f3e89ad1cb57976ff0ad99a107012ba3481d'])
          end
        end
      end

      it_behaves_like 'is a countable repository' do
        let(:repository) { instance }
      end

    end
  end

  it_behaves_like 'repository can be relocated', :git
end
