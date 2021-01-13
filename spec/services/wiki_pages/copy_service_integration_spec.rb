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

describe WikiPages::CopyService, 'integration', type: :model do
  let(:user) do
    FactoryBot.create(:user) do |user|
      FactoryBot.create(:member,
                        project: source_project,
                        principal: user,
                        roles: [role])

      FactoryBot.create(:member,
                        project: sink_project,
                        principal: user,
                        roles: [role])
    end
  end

  let(:role) do
    FactoryBot.create(:role,
                      permissions: permissions)
  end

  let(:permissions) do
    %i(view_wiki edit_wiki_pages)
  end
  let(:source_wiki) { FactoryBot.create(:wiki) }
  let(:source_project) { source_wiki.project }

  let(:sink_wiki) { FactoryBot.create(:wiki) }
  let(:sink_project) { sink_wiki.project }

  let(:wiki_page) { FactoryBot.create(:wiki_page_with_content) }

  let(:instance) { described_class.new(model: wiki_page, user: user) }

  let(:attributes) { {} }

  let(:copy) do
    service_result
      .result
  end
  let(:service_result) do
    instance
      .call(**attributes)
  end

  before do
    login_as(user)
  end

  describe '#call' do
    shared_examples_for 'copied wiki page' do
      it 'is a success' do
        expect(service_result)
          .to be_success
      end

      it 'is a new, persisted wiki page' do
        expect(copy).to be_persisted
        expect(copy.id).not_to eq(wiki_page.id)
      end

      it 'copies the content' do
        expect(copy.content.text).to eq(wiki_page.content.text)
      end

      it 'sets the author to be the current user' do
        expect(copy.content.author).to eq(user)
      end
    end

    describe 'to a different wiki' do
      let(:attributes) { { wiki: sink_wiki } }

      it_behaves_like 'copied wiki page'
    end
  end
end
