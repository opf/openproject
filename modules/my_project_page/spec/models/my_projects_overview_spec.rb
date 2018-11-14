#-- copyright
# OpenProject My Project Page Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

require 'spec_helper'

describe MyProjectsOverview, type: :model do
  let(:enabled_modules) { %w[activity work_package_tracking news wiki] }
  let(:project) { FactoryBot.create(:project, enabled_module_names: @enabled_module_names) }

  subject { MyProjectsOverview.new(project_id: project.id) }

  it 'sets default elements for new records if no elements are provided' do
    expect(subject.left).to match_array(%w(project_description project_details work_package_tracking))
    expect(subject.right).to match_array(%w(members news_latest))
    expect(subject.top).to be_empty
    expect(subject.hidden).to be_empty
  end

  it 'does not set default elements if elements are provided' do
    subject.left = %w(members)

    expect(subject.left).to match_array(%w(members))
    expect(subject.right).to match_array(%w(members news_latest))
    expect(subject.top).to be_empty
    expect(subject.hidden).to be_empty
  end


  it 'does not enforce default elements' do
    subject.right = []
    subject.save!

    subject.reload
    expect(subject.right).to match_array([])
  end

  describe '#custom_elements' do
    it "creates a new custom element as [idx, title, text]" do
      ce = subject.new_custom_element
      expect(ce[0]).to eq("a")
      expect(ce[1]).to be_kind_of String
      expect(ce[2]).to match(/^### Custom text/)
    end

    it "can save a custom element" do
      subject.hidden << subject.new_custom_element
      ce = subject.custom_elements.last
      expect(subject.save_custom_element(ce[0], "Title", "Content")).to be true
      expect(ce[1]).to eq("Title")
      expect(ce[2]).to eq("Content")
    end
  end
end
