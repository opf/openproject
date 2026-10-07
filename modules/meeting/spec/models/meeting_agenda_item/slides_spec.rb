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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require_relative "../../spec_helper"

RSpec.describe MeetingAgendaItem::Slides do
  let(:meeting_agenda_item) { build_stubbed(:meeting_agenda_item, notes:) }

  subject(:slides) { described_class.new(meeting_agenda_item) }

  context "without a horizontal rule" do
    let(:notes) { "Only slide" }

    it "has a single slide with all notes" do
      expect(slides.count).to eq(1)
      expect(slides.content(1)).to be_html_eql('<p class="op-uc-p">Only slide</p>')
    end
  end

  context "with horizontal rules" do
    let(:notes) do
      <<~MARKDOWN
        First slide

        ---

        Second slide

        * * *

        Third slide
      MARKDOWN
    end

    it "splits the notes at each rule" do
      expect(slides.count).to eq(3)
      expect(slides.content(1)).to be_html_eql('<p class="op-uc-p">First slide</p>')
      expect(slides.content(2)).to be_html_eql('<p class="op-uc-p">Second slide</p>')
      expect(slides.content(3)).to be_html_eql('<p class="op-uc-p">Third slide</p>')
    end

    it "returns html safe content without the rules" do
      expect(slides.content(2)).to be_html_safe
      expect(slides.content(2)).not_to include("<hr")
    end

    it "clamps slide numbers outside the range" do
      expect(slides.content(0)).to be_html_eql('<p class="op-uc-p">First slide</p>')
      expect(slides.content(nil)).to be_html_eql('<p class="op-uc-p">First slide</p>')
      expect(slides.content(4)).to be_html_eql('<p class="op-uc-p">Third slide</p>')
    end
  end

  context "with leading, trailing and consecutive rules" do
    let(:notes) do
      <<~MARKDOWN
        ---

        First slide

        ---

        ---

        Second slide

        ---
      MARKDOWN
    end

    it "skips empty slides" do
      expect(slides.count).to eq(2)
      expect(slides.content(2)).to be_html_eql('<p class="op-uc-p">Second slide</p>')
    end
  end

  context "with a rule nested inside a blockquote" do
    let(:notes) do
      <<~MARKDOWN
        > Quoted
        >
        > ---
        >
        > Still quoted
      MARKDOWN
    end

    it "does not split" do
      expect(slides.count).to eq(1)
      expect(slides.content(1)).to include("<hr>")
    end
  end

  context "without notes" do
    let(:notes) { "" }

    it "has a single empty slide" do
      expect(slides.count).to eq(1)
      expect(slides.content(1)).to eq("")
    end
  end
end
