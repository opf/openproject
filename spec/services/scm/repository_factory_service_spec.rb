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

require "spec_helper"

RSpec.describe SCM::RepositoryFactoryService do
  let(:user) { build(:user) }
  let(:project) { build(:project) }

  let(:enabled_scms) { ["subversion", "git"] }

  let(:params_hash) { {} }
  let(:params) { ActionController::Parameters.new params_hash }

  subject(:service) { SCM::RepositoryFactoryService.new(project, params) }

  before do
    allow(Setting).to receive(:enabled_scm).and_return(enabled_scms)
  end

  context "with empty hash" do
    it "does not build a repository" do
      expect { service.build_temporary }
        .to raise_error KeyError
      expect(service.repository).to be_nil
    end
  end

  context "with valid vendor" do
    let(:params_hash) do
      { scm_vendor: "subversion" }
    end

    it "allows temporary build repository" do
      expect(service.build_temporary).to be true
      expect(service.repository).not_to be_nil
    end

    it "does not allow to persist a repository" do
      expect { service.build_and_save }
        .to raise_error(ActionController::ParameterMissing)

      expect(service.repository).to be_nil
    end
  end

  context "with invalid vendor" do
    let(:params_hash) do
      { scm_vendor: "not_subversion", scm_type: "foo" }
    end

    it "does not allow to temporary build repository" do
      expect { service.build_temporary }.not_to raise_error

      expect(service.repository).to be_nil
      expect(service.build_error).to include("The SCM vendor not_subversion is disabled")
    end

    it "does not allow to persist a repository" do
      expect { service.build_temporary }.not_to raise_error

      expect(service.repository).to be_nil
      expect(service.build_error).to include("The SCM vendor not_subversion is disabled")
    end
  end

  context "with vendor and type" do
    let(:params_hash) do
      { scm_vendor: "subversion", scm_type: "existing" }
    end

    it "does not allow to persist a repository without URL" do
      expect(service.build_and_save).not_to be true

      expect(service.repository).to be_nil
      expect(service.build_error).to include("URL can't be blank")
    end
  end

  context "with invalid hash" do
    let(:params_hash) do
      {
        scm_vendor: "subversion", scm_type: "existing",
        repository: { url: "/tmp/foo.svn" }
      }
    end

    it "does not allow to persist a repository URL" do
      expect(service.build_and_save).not_to be true

      expect(service.repository).to be_nil
      expect(service.build_error).to include("URL is invalid")
    end
  end

  context "with valid hash" do
    let(:params_hash) do
      {
        scm_vendor: "subversion", scm_type: "existing",
        repository: { url: "file:///tmp/foo.svn" }
      }
    end

    it "allows to persist a repository without URL" do
      expect(service.build_and_save).to be true
      expect(service.repository).to be_a(Repository::Subversion)
    end
  end
end
