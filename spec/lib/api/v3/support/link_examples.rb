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

RSpec.shared_context "action link shared" do
  let(:all_permissions) { OpenProject::AccessControl.permissions.map(&:name) }
  let(:permissions) { all_permissions }
  let(:action_link_user) do
    defined?(user) ? user : build_stubbed(:user)
  end

  before do
    login_as(action_link_user)

    mock_permissions_for(action_link_user) do |mock|
      permissions.each do |permission|
        perm = OpenProject::AccessControl.permission(permission)
        mock.allow_globally perm.name if perm.global?
        mock.allow_in_project perm.name, project: project if perm.project?
      end
    end
  end

  it "indicates the desired method" do
    verb = begin
      # the standard method #method on an object interferes
      # with the let named 'method' conditionally defined
      method
    rescue ArgumentError
      :get
    end

    if verb == :get
      expect(subject)
        .not_to have_json_path("_links/#{link}/method")
    else
      expect(subject)
        .to be_json_eql(method.to_json)
        .at_path("_links/#{link}/method")
    end
  end

  describe "without permission" do
    let(:permissions) { all_permissions - Array(permission) }

    it_behaves_like "has no link"
  end
end

RSpec.shared_examples_for "has an untitled action link" do
  include_context "action link shared"

  it_behaves_like "has an untitled link"
end

RSpec.shared_examples_for "has a titled action link" do
  include_context "action link shared"

  it_behaves_like "has a titled link"
end

RSpec.shared_examples_for "has a titled link" do
  it { is_expected.to be_json_eql(href.to_json).at_path("_links/#{link}/href") }
  it { is_expected.to be_json_eql(title.to_json).at_path("_links/#{link}/title") }
end

RSpec.shared_examples_for "has an untitled link" do
  it { is_expected.to be_json_eql(href.to_json).at_path("_links/#{link}/href") }
  it { is_expected.not_to have_json_path("_links/#{link}/title") }
end

RSpec.shared_examples_for "has a templated link" do
  it { is_expected.to be_json_eql(href.to_json).at_path("_links/#{link}/href") }
  it { is_expected.to be_json_eql(true.to_json).at_path("_links/#{link}/templated") }
end

RSpec.shared_examples_for "has an empty link" do
  it { is_expected.to be_json_eql(nil.to_json).at_path("_links/#{link}/href") }

  it "has no embedded resource" do
    expect(subject).not_to have_json_path("_embedded/#{link}")
  end
end

RSpec.shared_examples_for "has an empty link collection" do
  it { is_expected.to be_json_eql([].to_json).at_path("_links/#{link}") }
end

RSpec.shared_examples_for "has a link collection" do
  it { is_expected.to be_json_eql(hrefs.to_json).at_path("_links/#{link}") }
end

RSpec.shared_examples_for "has no link" do
  it { is_expected.not_to have_json_path("_links/#{link}") }

  it "has no embedded resource" do
    expect(subject).not_to have_json_path("_embedded/#{link}")
  end
end
