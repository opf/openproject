#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require_relative './shared_contract_examples'
require 'contracts/shared/model_contract_shared_context'

describe Projects::InstantiateTemplateContract do
  include_context 'ModelContract shared context'

  let(:user) { FactoryBot.build_stubbed :user }
  let(:project) { Project.new name: 'Foo Bar', identifier: 'foo' }
  let(:template) { FactoryBot.build_stubbed :project }
  let(:options) { { template_project_id: template.id } }

  let(:contract) { described_class.new(project, user, options: options) }

  before do
    allow(user)
      .to(receive(:allowed_to_globally?))
      .with(:add_project)
      .and_return(allowed_to_add)

    allow(Project)
      .to receive_message_chain(:allowed_to, :where, :exists?)
      .and_return(allowed_to_copy)
  end

  context 'when user may copy template' do
    let(:allowed_to_copy) { true }
    let(:allowed_to_add) { true }

    it_behaves_like 'contract is valid'

    context 'but may not add projects' do
      let(:allowed_to_copy) { true }
      let(:allowed_to_add) { false }

      it_behaves_like 'contract is invalid', base: :error_unauthorized
    end
  end

  context 'when user may not copy template' do
    let(:allowed_to_copy) { false }
    let(:allowed_to_add) { true }

    it_behaves_like 'contract is invalid', base: :error_unauthorized
  end
end
