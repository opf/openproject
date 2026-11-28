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

require "rails_helper"

RSpec.describe Help::DocumentationArticle do
  subject(:article) { described_class.new("project-life-cycle") }

  it "reads the existing repository article without front matter" do
    expect(article.markdown).to include("## Schedule project phases")
    expect(article.markdown).not_to include("sidebar_navigation:")
  end

  it "connects methodology and implementation articles in each context" do
    expect(described_class.for_context("initiation").map(&:id))
      .to include("initiation-request", "initiating-phase", "initiation-settings", "pmflex-mapping")
  end

  it "resolves links to another selected repository article" do
    expect(article.linked_article("../../project-settings/project-life-cycle/").id).to eq("life-cycle-settings")
  end

  it "only accepts explicitly selected articles" do
    expect { described_class.new("../../config/database.yml") }.to raise_error(KeyError)
  end

  it "does not expose arbitrary files through the image endpoint" do
    expect { article.asset_path("../../config/database.yml") }.to raise_error(KeyError)
    expect { article.asset_path("unreferenced.png") }.to raise_error(KeyError)
  end

  it "keeps every selected source article available" do
    described_class::DIRECTORIES.each_key do |id|
      expect(described_class.new(id).path).to be_file
      expect(described_class.new(id).title).to be_present
    end
  end
end
