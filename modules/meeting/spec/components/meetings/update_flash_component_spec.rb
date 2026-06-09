# frozen_string_literal: true

require "rails_helper"

RSpec.describe Meetings::UpdateFlashComponent, type: :component do
  let(:project) { build_stubbed(:project) }
  let(:meeting) { build_stubbed(:meeting, project:) }
  let(:component) { described_class.new(meeting) }

  it "exposes a live region announcement" do
    expect(component.live_region_message).to eq I18n.t("notice_meeting_updated")
  end
end
