# frozen_string_literal: true

require "rails_helper"

RSpec.describe OpenProject::Common::DurationComponent, type: :component do
  let(:args) do
    {}
  end

  subject { described_class.new(duration, type, **args) }

  shared_examples "renders a duration" do |duration, type, **args|
    let(:duration) { duration }
    let(:type) { type }
    let(:args) { args }

    it "renders #{duration} #{type}" do
      expect(render_inline(subject).text).to eq(expected)
    end
  end

  context "with numeric duration" do
    it_behaves_like "renders a duration", 1, :minutes do
      let(:expected) { "1 minute" }
    end
    it_behaves_like "renders a duration", 20, :minutes do
      let(:expected) { "20 minutes" }
    end
    it_behaves_like "renders a duration", 63, :minutes do
      let(:expected) { "1 hour, 3 minutes" }
    end
    it_behaves_like "renders a duration", 125, :minutes, abbreviated: true do
      let(:expected) { "2 hrs, 5 mins" }
    end
  end

  context "with ISO8601 duration" do
    it_behaves_like "renders a duration", "P3DT12H25M" do
      let(:expected) { "3 days, 12 hours, 25 minutes" }
    end
  end

  context "with AS::Duration" do
    it_behaves_like "renders a duration", 3612.seconds do
      let(:expected) { "1 hour, 12 seconds" }
    end

    it_behaves_like "renders a duration", 3680.seconds do
      let(:expected) { "1 hour, 1 minute, 20 seconds" }
    end
  end

  context "when providing an invalid type" do
    let(:duration) { 1234 }
    let(:type) { :bogus }

    it "raises an error" do
      expected = "Provide known type (seconds, minutes, hours, days, weeks, months, years) " \
                 "when providing a number to this component."
      expect { subject }.to raise_error(ArgumentError, expected)
    end
  end

  context "when providing an invalid duration" do
    let(:duration) { %w[what's this] }
    let(:type) { :minutes }

    it "raises an error" do
      expect { subject }.to raise_error(ArgumentError, "Invalid duration type Array.")
    end
  end
end
