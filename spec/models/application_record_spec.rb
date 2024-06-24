require "spec_helper"

RSpec.describe ApplicationRecord do
  describe "#most_recently_changed" do
    let!(:work_package) do
      create(:work_package).tap do |wp|
        wp.update_column(:updated_at, 5.days.from_now)
      end
    end

    let!(:type) do
      create(:type).tap do |type|
        type.update_column(:updated_at, 1.day.from_now)
      end
    end

    let!(:status) { create(:status) }

    def expect_matched_date(postgres_time, rails_time)
      # Rails uses timestamp without timezone for timestamp columns
      postgres_utc_iso8601 = Time.zone.parse(postgres_time.to_s).iso8601
      rails_utc_iso8601 = rails_time.iso8601

      expect(postgres_utc_iso8601).to eq(rails_utc_iso8601)
    end

    it "returns the most recently changed timestamp of the given resource classes" do
      expect_matched_date described_class.most_recently_changed(WorkPackage, Type, Status),
                          work_package.updated_at

      expect_matched_date described_class.most_recently_changed(Status, Type),
                          type.updated_at

      expect_matched_date described_class.most_recently_changed(Status),
                          status.updated_at
    end
  end
end
