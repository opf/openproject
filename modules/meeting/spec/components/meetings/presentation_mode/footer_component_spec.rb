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

require "rails_helper"

RSpec.describe Meetings::PresentationMode::FooterComponent, type: :component do
  let(:project) { build_stubbed(:project) }
  let(:meeting) { build_stubbed(:meeting, project:) }
  let(:notes) { "One\n\n---\n\nTwo\n\n---\n\nThree" }
  let(:agenda_item) { build_stubbed(:meeting_agenda_item, meeting:, notes:) }
  let(:current_slide) { 1 }

  subject do
    render_inline(described_class.new(meeting:,
                                      sorted_agenda_item_ids: [agenda_item.id],
                                      current_item: agenda_item,
                                      current_slide:,
                                      started_at: Time.current))
    page
  end

  context "on the first slide of a single item" do
    it "allows moving to the next slide only" do
      expect(subject).to have_button("Previous", disabled: true)
      expect(subject).to have_link("Next", href: /slide=1/)
    end

    it "shows the slide progress" do
      expect(subject).to have_test_selector("meeting-presentation-slide-progress", text: "Slide 1/3")
    end
  end

  context "on a middle slide" do
    let(:current_slide) { 2 }

    it "allows moving in both directions" do
      expect(subject).to have_link("Previous", href: /slide=2/)
      expect(subject).to have_link("Next", href: /slide=2/)
    end
  end

  context "on the last slide of the last item" do
    let(:current_slide) { 3 }

    it "allows moving to the previous slide only" do
      expect(subject).to have_link("Previous")
      expect(subject).to have_button("Next", disabled: true)
    end
  end

  context "with a slide beyond the item's slides" do
    let(:current_slide) { 9 }

    it "treats it as the last slide" do
      expect(subject).to have_test_selector("meeting-presentation-slide-progress", text: "Slide 3/3")
      expect(subject).to have_button("Next", disabled: true)
    end
  end

  context "with notes without horizontal rules" do
    let(:notes) { "Only one slide" }

    it "does not show the slide progress" do
      expect(subject).not_to have_test_selector("meeting-presentation-slide-progress")
    end
  end
end
