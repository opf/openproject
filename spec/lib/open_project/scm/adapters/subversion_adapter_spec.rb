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
#++

require 'spec_helper'

describe OpenProject::Scm::Adapters::Subversion do
  let(:url) { '/tmp/bar.svn' }
  let(:config) { {} }
  let(:adapter) { OpenProject::Scm::Adapters::Subversion.new url }

  before do
    allow(adapter).to receive(:config).and_return(config)
  end

  describe 'client information' do
    it 'sets the Subversion client command' do
      expect(adapter.client_command).to eq('svn')
    end

    context 'with client command from config' do
      let(:config) { { client_command: '/usr/local/bin/svn' } }
      it 'overrides the Subversion client command from config' do
        expect(adapter.client_command).to eq('/usr/local/bin/svn')
      end
    end

    shared_examples 'correct client version' do |svn_string, expected_version|
      it 'should set the correct client version' do
        expect(adapter)
          .to receive(:scm_version_from_command_line)
          .and_return(svn_string)

        expect(adapter.client_version).to eq(expected_version)
      end
    end

    it_behaves_like 'correct client version', "svn, version 1.6.13 (r1002816)\n", [1, 6, 13]
    it_behaves_like 'correct client version', "svn, versione 1.6.13 (r1002816)\n", [1, 6, 13]
    it_behaves_like 'correct client version', "1.6.1\n1.7\n1.8", [1, 6, 1]
    it_behaves_like 'correct client version', "1.6.2\r\n1.8.1\r\n1.9.1", [1, 6, 2]
  end

  describe 'local repository' do
    with_filesystem_repository('subversion', 'svn') do |repo_dir|
      let(:url) { "file://#{repo_dir}" }

      it 'reads the Subversion version' do
        expect(adapter.client_version.length).to be >= 3
      end

      it 'is a valid repository' do
        expect(Dir.exists?(repo_dir)).to be true

        out, process = Open3.capture2e('svn', 'info', url)
        expect(process.exitstatus).to eq(0)
        expect(out).to include('Repository UUID')
      end

      it 'should be available' do
        expect(adapter).to be_available
        expect { adapter.check_availability! }.to_not raise_error
      end

      describe '.info' do
        it 'builds the info object' do
          info = adapter.info
          expect(info.root_url).to eq(url)
          expect(info.lastrev.identifier).to eq('12')
          expect(info.lastrev.author).to eq('oliver')
          expect(info.lastrev.time).to eq('2015-07-08T13:32:29.228572Z')
        end
      end

      describe '.entries' do
        it 'reads all entries from the current revision' do
          entries = adapter.entries
          expect(entries.length).to eq(1)

          expect(entries[0].name).to eq('subversion_test')
          expect(entries[0].path).to eq('subversion_test')
        end

        it 'contains a reference to the last revision' do
          entries = adapter.entries
          expect(entries.length).to eq(1)
          lastrev = entries[0].lastrev

          expect(lastrev.identifier).to eq('12')
          expect(lastrev.author).to eq('oliver')
          expect(lastrev.message).to eq('')
          expect(lastrev.time).to eq('2015-07-08T13:32:29.228572Z')
        end

        it 'reads all entries from the given revision' do
          entries = adapter.entries(nil, 1)
          expect(entries.length).to eq(1)
          lastrev = entries[0].lastrev

          expect(lastrev.identifier).to eq('1')
          expect(lastrev.author).to eq('jp')
          expect(lastrev.message).to eq('')
          expect(lastrev.time).to eq('2007-09-10T16:54:38.484000Z')
        end

        it 'reads all entries from the given path' do
          entries = adapter.entries('subversion_test')
          expect(entries.length).to eq(5)

          expect(entries[0].name).to eq('[folder_with_brackets]')
          expect(entries[0].path).to eq('subversion_test/[folder_with_brackets]')
          expect(entries[0]).to be_dir
          expect(entries[0]).not_to be_file
          expect(entries[0].size).to be_nil

          expect(entries[1].name).to eq('folder')
          expect(entries[1].path).to eq('subversion_test/folder')
          expect(entries[1]).to be_dir
          expect(entries[1]).not_to be_file
          expect(entries[1].size).to be_nil

          expect(entries[4].name).to eq('textfile.txt')
          expect(entries[4].path).to eq('subversion_test/textfile.txt')
          expect(entries[4]).to_not be_dir
          expect(entries[4]).to be_file
          expect(entries[4]).not_to be_dir
          expect(entries[4].size).to eq(756)
        end

        it 'reads all entries from the given path and revision' do
          entries = adapter.entries('subversion_test', '2')
          expect(entries.length).to eq(4)
          expect(entries[0].name).to eq('folder')
          expect(entries[0].path).to eq('subversion_test/folder')

          expect(entries[1].name).to eq('.project')
          expect(entries[1].path).to eq('subversion_test/.project')

          expect(entries[2].name).to eq('helloworld.rb')
          expect(entries[2].path).to eq('subversion_test/helloworld.rb')

          expect(entries[3].name).to eq('textfile.txt')
          expect(entries[3].path).to eq('subversion_test/textfile.txt')
        end
      end

      describe '.properties' do
        it 'returns an empty hash for no properties' do
          expect(adapter.properties('')).to eq({})
        end

        it 'returns the properties when available' do
          expect(adapter.properties('subversion_test')).to eq('svn:ignore' => "foo\nbar/\n")
        end

        it 'does not return the properties from an older revision on the same path' do
          expect(adapter.properties('subversion_test', 11)).to eq({})
        end
      end

      describe '.revisions' do
        it 'returns all revisions by default' do
          revisions = adapter.revisions
          expect(revisions.length).to eq(12)

          expect(revisions[0].author).to eq('oliver')
          expect(revisions[0].message).to eq("Propedit\n")

          revisions.each_with_index do |rev, i|
            expect(rev.identifier).to eq((12 - i).to_s)
          end
        end

        it 'returns revisions for a specific path' do
          revisions = adapter.revisions('subversion_test/[folder_with_brackets]', nil, nil,
                                        with_paths: true)

          expect(revisions.length).to eq(1)
          expect(revisions[0].identifier).to eq('11')

          paths = revisions[0].paths
          expect(paths.length).to eq(2)
          expect(paths[0]).to eq(action: 'A', path: '/subversion_test/[folder_with_brackets]',
                                 from_path: nil, from_revision: nil)
        end

        it 'returns revision for a specific path and revision' do
          # Folder was added in rev 2
          expect { adapter.revisions('subversion_test/folder', 1) }
            .to raise_error(OpenProject::Scm::Exceptions::CommandFailed)

          revisions = adapter.revisions('subversion_test/folder', 2, nil,
                                        with_paths: true)

          expect(revisions.length).to eq(1)
          expect(revisions[0].identifier).to eq('2')

          paths = revisions[0].paths
          expect(paths.length).to eq(7)
        end

        it 'returns revision for a specific range' do
          revisions = adapter.revisions('subversion_test/folder', 2, 5,
                                        with_paths: true)
          expect(revisions.length).to eq(2)
          expect(revisions[0].identifier).to eq('2')
          expect(revisions[0].message).to eq('Initial import.')
          expect(revisions[1].identifier).to eq('5')
          expect(revisions[1].message).to eq('Modified one file in the folder.')

          expect(revisions[0].paths.length).to eq(7)
          expect(revisions[1].paths.length).to eq(1)
        end
      end

      describe '.blame' do
        it 'blames an existing file at the given path' do
          annotate = adapter.annotate('subversion_test/[folder_with_brackets]/README.txt')
          expect(annotate.lines.length).to eq(2)
          expect(annotate.revisions.length).to eq(2)

          expect(annotate.revisions[0].identifier).to eq('11')
          expect(annotate.revisions[0].author).to eq('schmidt')
        end

        it 'outputs nothing for an invalid blame target' do
          annotate = adapter.annotate('subversion_test/[folder_with_brackets]/README.txt', 10)
          expect(annotate.lines.length).to eq(0)
          expect(annotate.revisions.length).to eq(0)
        end
      end

      describe '.cat' do
        it 'outputs the given file' do
          out = adapter.cat('subversion_test/[folder_with_brackets]/README.txt', 11)
          expect(out).to eq('This file should be accessible for Redmine, '\
                            "although its folder contains square\nbrackets.\n")
        end

        it 'raises an exception for an invalid file' do
          expect { adapter.cat('subversion_test/[folder_with_brackets]/README.txt', 10) }
            .to raise_error(OpenProject::Scm::Exceptions::CommandFailed)
        end
      end

      describe '.diff' do
        it 'provides a full diff against the last revision' do
          diff = adapter.diff('', 12)
          expect(diff.join("\n")).to include('Added: svn:ignore')
        end

        it 'provides a negative diff' do
          diff = adapter.diff('', 11, 12)
          expect(diff.join("\n")).to include('Deleted: svn:ignore')
        end

        it 'provides the complete for the given range' do
          diff = adapter.diff('', 8, 6).join("\n")
          expect(diff).to include('Index: subversion_test/folder/greeter.rb')
          expect(diff).to include('Index: subversion_test/helloworld.c')
        end

        it 'provides the selected diff for the given range' do
          diff = adapter.diff('subversion_test/helloworld.c', 8, 6)
          expect(diff).to eq(<<-DIFF.strip_heredoc.split("\n"))
            Index: helloworld.c
            ===================================================================
            --- helloworld.c	(revision 6)
            +++ helloworld.c	(revision 8)
            @@ -3,6 +3,5 @@
             int main(void)
             {
                 printf("hello, world\\n");
            -
                 return 0;
             }
          DIFF
        end
      end
    end
  end
end
