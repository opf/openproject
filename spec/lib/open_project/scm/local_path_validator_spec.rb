# frozen_string_literal: true

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

RSpec.describe OpenProject::SCM::LocalPathValidator do
  let(:checkout_root)    { "/srv/openproject/repositories" }
  let(:managed_git_root) { "/srv/openproject/git" }
  let(:managed_svn_root) { "/srv/openproject/svn" }

  before do
    allow(OpenProject::Configuration).to receive(:scm_local_checkout_path).and_return(checkout_root)
    allow(Repository::Git).to receive(:managed_root).and_return(managed_git_root)
    allow(Repository::Subversion).to receive(:managed_root).and_return(managed_svn_root)
  end

  describe ".local_path" do
    subject { described_class.local_path(value) }

    context "with a simple absolute path" do
      let(:value) { "/srv/openproject/git/myproject.git" }

      it { is_expected.to eq("/srv/openproject/git/myproject.git") }
    end

    context "with a standard file:// URL" do
      let(:value) { "file:///srv/openproject/git/myproject.git" }

      it { is_expected.to eq("/srv/openproject/git/myproject.git") }
    end

    context "with a file:// URL with localhost authority" do
      let(:value) { "file://localhost/srv/openproject/git/myproject.git" }

      it { is_expected.to eq("/srv/openproject/git/myproject.git") }
    end

    context "with triple-slash bare path (///path)" do
      let(:value) { "///srv/openproject/git/myproject.git" }

      it "normalises to a single leading slash" do
        expect(subject).to eq("/srv/openproject/git/myproject.git")
      end
    end

    context "with double-slash bare path (//path)" do
      let(:value) { "//srv/openproject/git/myproject.git" }

      it "normalises to a single leading slash" do
        expect(subject).to eq("/srv/openproject/git/myproject.git")
      end
    end

    context "with file URL containing quadruple slashes (file:////path)" do
      let(:value) { "file:////srv/openproject/git/myproject.git" }

      it "normalises to a single leading slash" do
        expect(subject).to eq("/srv/openproject/git/myproject.git")
      end
    end

    context "with dot-dot path segments" do
      let(:value) { "/srv/openproject/git/../git/myproject.git" }

      it "resolves the traversal" do
        expect(subject).to eq("/srv/openproject/git/myproject.git")
      end
    end

    context "with an http URL" do
      let(:value) { "https://github.com/example/repo.git" }

      it { is_expected.to be_nil }
    end

    context "with a git protocol URL" do
      let(:value) { "git://github.com/example/repo.git" }

      it { is_expected.to be_nil }
    end

    context "with a relative path" do
      let(:value) { "relative/path/repo.git" }

      it { is_expected.to be_nil }
    end

    context "with a blank value" do
      let(:value) { "" }

      it { is_expected.to be_nil }
    end
  end

  describe ".points_to_openproject_directory?" do
    subject { described_class.points_to_openproject_directory?(value) }

    shared_examples "flagged as forbidden" do
      it { is_expected.to be true }
    end

    shared_examples "allowed through" do
      it { is_expected.to be false }
    end

    context "with plain absolute path inside git managed root" do
      let(:value) { "#{managed_git_root}/other-project.git" }

      it_behaves_like "flagged as forbidden"
    end

    context "with plain absolute path inside checkout root" do
      let(:value) { "#{checkout_root}/other-project" }

      it_behaves_like "flagged as forbidden"
    end

    context "with plain absolute path inside svn managed root" do
      let(:value) { "#{managed_svn_root}/other-project" }

      it_behaves_like "flagged as forbidden"
    end

    context "with standard file:// URL inside managed root" do
      let(:value) { "file://#{managed_git_root}/other-project.git" }

      it_behaves_like "flagged as forbidden"
    end

    # Bypass A: triple-slash bare path (URI::Error rescue path)
    context "with triple-slash path (///path) inside managed root" do
      let(:value) { "///#{managed_git_root.delete_prefix('/')}/other-project.git" }

      it_behaves_like "flagged as forbidden"
    end

    # Bypass B: double-slash bare path (// survives File.expand_path on POSIX)
    context "with double-slash path (//path) inside managed root" do
      let(:value) { "//#{managed_git_root.delete_prefix('/')}/other-project.git" }

      it_behaves_like "flagged as forbidden"
    end

    # Bypass B/C: file URL with quadruple slashes (parsed.path starts with //)
    context "with file URL with quadruple slashes (file:////path) inside managed root" do
      let(:value) { "file:////#{managed_git_root.delete_prefix('/')}/other-project.git" }

      it_behaves_like "flagged as forbidden"
    end

    context "with file URL with localhost authority inside managed root" do
      let(:value) { "file://localhost#{managed_git_root}/other-project.git" }

      it_behaves_like "flagged as forbidden"
    end

    context "with path with dot-dot traversal resolving into managed root" do
      let(:value) { "/external/../#{managed_git_root.delete_prefix('/')}/other-project.git" }

      it_behaves_like "flagged as forbidden"
    end

    context "with external bare git repository" do
      let(:value) { "/srv/external/repos/myrepo.git" }

      it_behaves_like "allowed through"
    end

    context "with https remote URL" do
      let(:value) { "https://github.com/example/repo.git" }

      it_behaves_like "allowed through"
    end

    context "with path that only shares a prefix with managed root" do
      let(:value) { "#{managed_git_root}-extra/repo.git" }

      it_behaves_like "allowed through"
    end

    context "when blank value" do
      let(:value) { nil }

      it_behaves_like "allowed through"
    end
  end
end
