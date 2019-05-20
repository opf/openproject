#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

describe ::API::V3::Members::MemberRepresenter, 'rendering' do
  include ::API::V3::Utilities::PathHelper

  let(:member) do
    FactoryBot.build_stubbed(:member,
                             roles: roles,
                             user: user,
                             project: project)
  end
  let(:project) { FactoryBot.build_stubbed(:project) }
  let(:roles) { [role1, role2] }
  let(:role1) { FactoryBot.build_stubbed(:role) }
  let(:role2) { FactoryBot.build_stubbed(:role) }
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:current_user) { FactoryBot.build_stubbed(:user) }
  let(:permissions) do
    [:manage_members]
  end
  let(:representer) do
    described_class.create(member, current_user: current_user, embed_links: true)
  end

  subject { representer.to_json }

  before do
    allow(current_user)
      .to receive(:allowed_to?) do |permission, context_project|
      project == context_project && permissions.include?(permission)
    end
  end

  describe '_links' do
    it_behaves_like 'has a titled link' do
      let(:link) { 'self' }
      let(:href) { api_v3_paths.member member.id }
      let(:title) { user.name }
    end
  end

  describe 'properties' do
    it_behaves_like 'property', :_type do
      let(:value) { 'Member' }
    end

    it_behaves_like 'property', :id do
      let(:value) { member.id }
    end
  end
end
