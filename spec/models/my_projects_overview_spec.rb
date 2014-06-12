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

require File.dirname(__FILE__) + '/../spec_helper'

describe MyProjectsOverview do
  before do
    @enabled_module_names = %w[activity work_package_tracking news wiki]
    FactoryGirl.create(:project, :enabled_module_names => @enabled_module_names)
    @project = Project.find(:first)
    @overview = MyProjectsOverview.create(:project_id => @project.id)
  end

  it 'sets default elements for new records if no elements are provided' do
    o = MyProjectsOverview.new
    expect(o.left).to match_array(["project_description", "project_details", "work_package_tracking"])
    expect(o.right).to match_array(["members", "news_latest"])
    expect(o.top).to match_array([])
    expect(o.hidden).to match_array([])
  end

  it 'does not set default elements if elements are provided' do
    o = MyProjectsOverview.new :left => ["members"]
    expect(o.left).to match_array(["members"])
    expect(o.right).to match_array(["members", "news_latest"])
    expect(o.top).to match_array([])
    expect(o.hidden).to match_array([])
  end


  it 'does not enforce default elements' do
    @overview.right = []
    @overview.save!

    @overview.reload
    expect(@overview.right).to match_array([])
  end

  it 'creates a new custom element' do
    expect(@overview.new_custom_element).not_to be_nil
  end

  it "creates a new custom element as [idx, title, text]" do
    ce = @overview.new_custom_element
    expect(ce[0]).to eq("a")
    expect(ce[1]).to be_kind_of String
    expect(ce[2]).to match(/^h3\./)
  end

  it "can save a custom element" do
    @overview.hidden << @overview.new_custom_element
    ce = @overview.custom_elements.last
    expect(@overview.save_custom_element(ce[0], "Title", "Content")).to be true
    expect(ce[1]).to eq("Title")
    expect(ce[2]).to eq("Content")
  end

  it "should always show attachments" do
    expect(@overview.attachments_visible?(nil)).to be true
  end
end
