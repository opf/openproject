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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Creating a local project repository",
               :skip_csrf,
               type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %w[repository]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[manage_repository browse_repository] })
  end

  let(:allowed_root) { Dir.mktmpdir("allowed_root") }
  let(:other_root) { Dir.mktmpdir("other_root") }
  let(:allowed_local_paths) { [] }

  before do
    allow(Setting).to receive(:enabled_scm).and_return(%w[git])
    with_config("scm" => { "git" => { "allowed_local_paths" => allowed_local_paths } })
    login_as user
  end

  after do
    FileUtils.remove_entry(allowed_root)
    FileUtils.remove_entry(other_root)
  end

  def create_repository(url)
    post project_repository_path(project),
         params: { scm_vendor: "git", scm_type: "local", repository: { url: } }
  end

  context "without allowed local paths" do
    it "does not link a path" do
      create_repository(other_root)

      expect(project.reload.repository).to be_nil
    end

    it "does not link a file URL" do
      create_repository("file://#{other_root}")

      expect(project.reload.repository).to be_nil
    end
  end

  context "with an allowed local path" do
    let(:allowed_local_paths) { [allowed_root] }

    it "links a path inside it" do
      FileUtils.mkdir(File.join(allowed_root, "repo.git"))
      create_repository(File.join(allowed_root, "repo.git"))

      expect(project.reload.repository).to be_present
    end

    it "does not link a path outside it" do
      create_repository(other_root)

      expect(project.reload.repository).to be_nil
    end

    it "does not link a path that leaves it through ../" do
      create_repository(File.join(allowed_root, "..", File.basename(other_root)))

      expect(project.reload.repository).to be_nil
    end

    it "does not link a symlink inside it that points outside" do
      File.symlink(other_root, File.join(allowed_root, "link"))
      create_repository(File.join(allowed_root, "link"))

      expect(project.reload.repository).to be_nil
    end

    it "does not link a missing path below a symlink inside it that points outside" do
      File.symlink(other_root, File.join(allowed_root, "link"))
      create_repository(File.join(allowed_root, "link", "missing.git"))

      expect(project.reload.repository).to be_nil
    end
  end
end
