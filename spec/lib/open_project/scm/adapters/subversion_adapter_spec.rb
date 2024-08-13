#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

require "spec_helper"

RSpec.describe OpenProject::SCM::Adapters::Subversion do
  let(:root_url) { "/tmp/bar.svn" }
  let(:url) { "file://#{root_url}" }
  let(:config) { {} }
  let(:adapter) { OpenProject::SCM::Adapters::Subversion.new url, root_url }

  before do
    allow(adapter.class).to receive(:config).and_return(config)
  end

  describe "client information" do
    it "sets the Subversion client command" do
      expect(adapter.client_command).to eq("svn")
    end

    context "with client command from config" do
      let(:config) { { client_command: "/usr/local/bin/svn" } }

      it "overrides the Subversion client command from config" do
        expect(adapter.client_command).to eq("/usr/local/bin/svn")
      end
    end

    shared_examples "correct client version" do |svn_string, expected_version|
      it "sets the correct client version" do
        expect(adapter)
          .to receive(:scm_version_from_command_line)
          .and_return(svn_string)

        expect(adapter.client_version).to eq(expected_version)
        expect(adapter.client_available).to be true
        expect(adapter.client_version_string).to eq(expected_version.join("."))
      end
    end

    it_behaves_like "correct client version", "svn, version 1.6.13 (r1002816)\n", [1, 6, 13]
    it_behaves_like "correct client version", "svn, versione 1.6.13 (r1002816)\n", [1, 6, 13]
    it_behaves_like "correct client version", "1.6.1\n1.7\n1.8", [1, 6, 1]
    it_behaves_like "correct client version", "1.6.2\r\n1.8.1\r\n1.9.1", [1, 6, 2]
  end

  describe "invalid repository" do
    describe ".check_availability!", skip_if_command_unavailable: "svnadmin" do
      it "is not available" do
        expect(Dir.exist?(url)).to be false
        expect(adapter).not_to be_available
        expect { adapter.check_availability! }
          .to raise_error(OpenProject::SCM::Exceptions::SCMUnavailable)
      end

      it "raises a meaningful error if shell output fails" do
        error_string = <<~ERR
          svn: E215004: Authentication failed and interactive prompting is disabled; see the --force-interactive option
          svn: E215004: Unable to connect to a repository at URL 'file:///tmp/bar.svn'
          svn: E215004: No more credentials or we tried too many times.
          Authentication failed
        ERR

        allow(adapter).to receive(:popen3)
          .and_yield(StringIO.new(""), StringIO.new(error_string))

        expect { adapter.check_availability! }
          .to raise_error(OpenProject::SCM::Exceptions::SCMUnauthorized)
      end
    end
  end

  describe "repository with authorization" do
    let(:adapter) { OpenProject::SCM::Adapters::Subversion.new url, root_url, login, password }
    let(:login) { "whatever@example.org" }
    let(:svn_cmd) { adapter.send :build_svn_cmd, ["info"] }

    context "without password" do
      let(:password) { nil }

      it "creates the subversion command" do
        idx = svn_cmd.index("--username")
        expect(idx).not_to be_nil
        expect(svn_cmd[idx + 1]).to eq(login)
        expect(svn_cmd).not_to include("--password")
      end
    end

    context "with password" do
      let(:password) { 'VG%\';rm -rf /;},Y<lo>^m\+DuE,vJP/9' }

      it "creates the subversion command" do
        idx = svn_cmd.index("--username")
        expect(idx).not_to be_nil
        expect(svn_cmd[idx + 1]).to eq(login)

        idx = svn_cmd.index("--password")
        expect(idx).not_to be_nil
        expect(password)
      end
    end
  end

  describe "empty repository" do
    include_context "with tmpdir"
    let(:root_url) { tmpdir }

    describe ".create_empty_svn", skip_if_command_unavailable: "svnadmin" do
      context "with valid root_url" do
        it "creates the repository" do
          expect(Dir.exist?(root_url)).to be true
          expect(Dir.entries(root_url).length).to eq 2
          expect { adapter.create_empty_svn }.not_to raise_error

          expect(Dir.exist?(root_url)).to be true
          expect(Dir.entries(root_url).length).to be >= 5
        end
      end

      context "with non-existing root_url" do
        let(:root_url) { File.join(tmpdir, "foo", "bar") }

        it "fails" do
          expect { adapter.create_empty_svn }
            .to raise_error(OpenProject::SCM::Exceptions::CommandFailed)

          expect(Dir.exist?(root_url)).to be false
        end
      end
    end

    describe ".check_availability!", skip_if_command_unavailable: "svnadmin" do
      it "is marked empty" do
        adapter.create_empty_svn
        expect { adapter.check_availability! }
          .to raise_error(OpenProject::SCM::Exceptions::SCMEmpty)
      end
    end
  end

  describe "local repository" do
    with_subversion_repository do |repo_dir|
      let(:root_url) { repo_dir }

      it "reads the Subversion version" do
        expect(adapter.client_version.length).to be >= 3
      end

      it "is a valid repository" do
        expect(Dir.exist?(repo_dir)).to be true

        out, process = Open3.capture2e("svn", "info", url)
        expect(process.exitstatus).to eq(0)
        expect(out).to include("Repository UUID")
      end

      it "is available" do
        expect(adapter).to be_available
        expect { adapter.check_availability! }.not_to raise_error
      end

      describe ".info" do
        it "builds the info object" do
          info = adapter.info
          expect(info.root_url).to eq(url)
          expect(info.lastrev.identifier).to eq("14")
          expect(info.lastrev.author).to eq("mkahl")
          expect(info.lastrev.time.getlocal("+01:00").strftime("%FT%T%:z")).to eq("2017-05-04T14:26:53+01:00")
        end
      end

      describe ".entries" do
        it "reads all entries from the current revision" do
          entries = adapter.entries
          expect(entries.length).to eq(10)

          expect(entries[0].name).to eq("Föbar")
          expect(entries[0].path).to eq("Föbar")
          expect(entries[1].name).to eq("folder_a")
          expect(entries[1].path).to eq("folder_a")
        end

        it "contains a reference to the last revision" do
          entries = adapter.entries
          expect(entries.length).to eq(10)
          lastrev = entries[0].lastrev

          expect(lastrev.identifier).to eq("13")
          expect(lastrev.author).to eq("oliver")
          expect(lastrev.message).to eq("")
          expect(lastrev.time.getlocal("+01:00").strftime("%FT%T%:z")).to eq("2016-04-14T20:23:01+01:00")
        end

        it "reads all entries from the given revision" do
          entries = adapter.entries(nil, 1)
          expect(entries.length).to eq(1)
          lastrev = entries[0].lastrev

          expect(lastrev.identifier).to eq("1")
          expect(lastrev.author).to eq("jp")
          expect(lastrev.message).to eq("")
          expect(lastrev.time).to eq("2007-09-10T16:54:38.484000Z")
        end

        it "reads all entries from the given path" do
          entries = adapter.entries("subversion_test")
          expect(entries.length).to eq(5)

          expect(entries[0].name).to eq("[folder_with_brackets]")
          expect(entries[0].path).to eq("subversion_test/[folder_with_brackets]")
          expect(entries[0]).to be_dir
          expect(entries[0]).not_to be_file
          expect(entries[0].size).to be_nil

          expect(entries[1].name).to eq("folder")
          expect(entries[1].path).to eq("subversion_test/folder")
          expect(entries[1]).to be_dir
          expect(entries[1]).not_to be_file
          expect(entries[1].size).to be_nil

          expect(entries[4].name).to eq("textfile.txt")
          expect(entries[4].path).to eq("subversion_test/textfile.txt")
          expect(entries[4]).not_to be_dir
          expect(entries[4]).to be_file
          expect(entries[4]).not_to be_dir
          expect(entries[4].size).to eq(756)
        end

        it "reads all entries from the given path and revision" do
          entries = adapter.entries("subversion_test", "2")
          expect(entries.length).to eq(4)
          expect(entries[0].name).to eq("folder")
          expect(entries[0].path).to eq("subversion_test/folder")

          expect(entries[1].name).to eq(".project")
          expect(entries[1].path).to eq("subversion_test/.project")

          expect(entries[2].name).to eq("helloworld.rb")
          expect(entries[2].path).to eq("subversion_test/helloworld.rb")

          expect(entries[3].name).to eq("textfile.txt")
          expect(entries[3].path).to eq("subversion_test/textfile.txt")
        end
      end

      describe ".properties" do
        it "returns an empty hash for no properties" do
          expect(adapter.properties("")).to eq({})
        end

        it "returns the properties when available" do
          expect(adapter.properties("subversion_test")).to eq("svn:ignore" => "foo\nbar/\n")
        end

        it "does not return the properties from an older revision on the same path" do
          expect(adapter.properties("subversion_test", 11)).to eq({})
        end
      end

      describe ".revisions" do
        it "returns all revisions by default" do
          revisions = adapter.revisions
          expect(revisions.length).to eq(14)

          expect(revisions[0].author).to eq("mkahl")
          expect(revisions[0].message.strip).to eq("added some more files to work with")

          revisions.each_with_index do |rev, i|
            expect(rev.identifier).to eq((14 - i).to_s)
          end
        end

        it "returns revisions for a specific path" do
          revisions = adapter.revisions("subversion_test/[folder_with_brackets]", nil, nil,
                                        with_paths: true)

          expect(revisions.length).to eq(1)
          expect(revisions[0].identifier).to eq("11")
          expect(revisions[0].format_identifier).to eq("11")

          paths = revisions[0].paths
          expect(paths.length).to eq(2)
          expect(paths[0]).to eq(action: "A", path: "/subversion_test/[folder_with_brackets]",
                                 from_path: nil, from_revision: nil)
        end

        it "returns revision for a specific path and revision" do
          # Folder was added in rev 2
          expect { adapter.revisions("subversion_test/folder", 1) }
            .to raise_error(OpenProject::SCM::Exceptions::CommandFailed)

          revisions = adapter.revisions("subversion_test/folder", 2, nil,
                                        with_paths: true)

          expect(revisions.length).to eq(1)
          expect(revisions[0].identifier).to eq("2")

          paths = revisions[0].paths
          expect(paths.length).to eq(7)
        end

        it "returns revision for a specific range" do
          revisions = adapter.revisions("subversion_test/folder", 2, 5,
                                        with_paths: true)
          expect(revisions.length).to eq(2)
          expect(revisions[0].identifier).to eq("2")
          expect(revisions[0].message).to eq("Initial import.")
          expect(revisions[1].identifier).to eq("5")
          expect(revisions[1].message).to eq("Modified one file in the folder.")

          expect(revisions[0].paths.length).to eq(7)
          expect(revisions[1].paths.length).to eq(1)
        end
      end

      describe ".blame" do
        it "blames an existing file at the given path" do
          annotate = adapter.annotate("subversion_test/[folder_with_brackets]/README.txt")
          expect(annotate.lines.length).to eq(2)
          expect(annotate.revisions.length).to eq(2)

          expect(annotate.revisions[0].identifier).to eq("11")
          expect(annotate.revisions[0].author).to eq("schmidt")
        end

        it "outputs nothing for an invalid blame target" do
          annotate = adapter.annotate("subversion_test/[folder_with_brackets]/README.txt", 10)
          expect(annotate.lines.length).to eq(0)
          expect(annotate.revisions.length).to eq(0)
        end
      end

      describe ".cat" do
        it "outputs the given file" do
          out = adapter.cat("subversion_test/[folder_with_brackets]/README.txt", 11)
          expect(out).to eq("This file should be accessible for Redmine, " \
                            "although its folder contains square\nbrackets.\n")
        end

        it "raises an exception for an invalid file" do
          expect { adapter.cat("subversion_test/[folder_with_brackets]/README.txt", 10) }
            .to raise_error(OpenProject::SCM::Exceptions::CommandFailed)
        end
      end

      describe ".diff" do
        it "provides a full diff against the last revision" do
          diff = adapter.diff("", 12).map(&:chomp)
          expect(diff.join("\n")).to include("Added: svn:ignore")
        end

        it "provides a negative diff" do
          diff = adapter.diff("", 11, 12).map(&:chomp)
          expect(diff.join("\n")).to include("Deleted: svn:ignore")
        end

        it "provides the complete for the given range" do
          diff = adapter.diff("", 8, 6).map(&:chomp).join("\n")
          expect(diff).to include("Index: subversion_test/folder/greeter.rb")
          expect(diff).to include("Index: subversion_test/helloworld.c")
        end

        it "provides the selected diff for the given range" do
          diff = adapter.diff("subversion_test/helloworld.c", 8, 6).map(&:chomp)
          expect(diff).to eq(<<~DIFF.split("\n"))
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
