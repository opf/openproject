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

RSpec.describe Calendar::CalendarsController do
  let(:project) do
    build_stubbed(:project).tap do |p|
      allow(Project)
        .to receive(:find)
        .with(p.id.to_s)
        .and_return(p)
    end
  end
  let(:permissions) { [:view_calendar] }
  let(:user) { build_stubbed(:user) }

  before do
    mock_permissions_for(user) do |mock|
      mock.allow_in_project *permissions, project:
    end

    login_as user
  end

  describe "#index" do
    shared_examples_for "calendar#index" do
      subject { response }

      it { is_expected.to be_successful }

      it { is_expected.to render_template("calendar/calendars/index") }
    end

    context "within a project context" do
      before do
        get :index, params: { project_id: project.id }
      end

      it_behaves_like "calendar#index"
    end

    context "within a global context" do
      before do
        get :index
      end

      it_behaves_like "calendar#index"
    end
  end
end
