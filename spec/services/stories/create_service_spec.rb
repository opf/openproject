#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013-2014 the OpenProject Foundation (OPF)
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Stories::CreateService, type: :model do
  let(:priority) { FactoryGirl.create(:priority) }
  let(:project) do
    project = FactoryGirl.create(:project, types: [type_feature])

    FactoryGirl.create(:member,
                       principal: user,
                       project: project,
                       roles: [role])
    project
  end
  let(:role) { FactoryGirl.create(:role, permissions: permissions) }
  let(:permissions) { %i(add_work_packages manage_subtasks) }
  let(:status) { FactoryGirl.create(:status) }
  let(:type_feature) { FactoryGirl.create(:type_feature) }

  let(:user) do
    FactoryGirl.create(:user)
  end

  let(:instance) do
    Stories::CreateService
      .new(user: user)
  end

  let(:attributes) do
    {
      project: project,
      status: status,
      type: type_feature,
      priority: priority,
      parent_id: story.id,
      remaining_hours: remaining_hours,
      subject: 'some subject'
    }
  end

  let(:version) { FactoryGirl.create(:version, project: project) }

  let(:story) do
    project.enabled_module_names += ['backlogs']

    FactoryGirl.create(:story, fixed_version: version,
                               project: project,
                               status: status,
                               type: type_feature,
                               priority: priority)
  end

  before do
    allow(User).to receive(:current).and_return(user)
  end

  subject { instance.call(attributes: attributes) }

  describe "remaining_hours" do
    before do
      subject
    end

    context 'with the story having remaining_hours' do
      let(:remaining_hours) { 15.0 }

      it 'does update the parents remaining hours' do
        expect(story.reload.remaining_hours).to eq(15)
      end
    end

    context 'with the subtask not having remaining_hours' do
      let(:remaining_hours) { nil }

      it 'does not note remaining hours to be changed' do
        expect(story.reload.remaining_hours).to be_nil
      end
    end
  end
end
