# frozen_string_literal: true

require "rails_helper"

RSpec.describe OpTurbo::ComponentStream do
  described_module = described_class

  controller(ApplicationController) do
    include described_module

    no_authorization_required! :update

    def update
      dispatch_event_via_turbo_stream(params[:event_name], detail: { work_package_id: 42 })
      respond_to_with_turbo_streams
    end
  end

  current_user { build_stubbed(:user) }

  before do
    routes.draw { get "update" => "anonymous#update" }
  end

  describe "#dispatch_event_via_turbo_stream" do
    context "when the event name is prefixed with op-dispatched:" do
      it "renders a dispatchEvent turbo stream carrying the detail" do
        get :update, params: { event_name: "op-dispatched:resource-allocations:changed" }, as: :turbo_stream

        expect(response.body).to have_turbo_stream(action: "dispatchEvent")
        expect(response.body).to include 'event-name="op-dispatched:resource-allocations:changed"'

        stream = Nokogiri::HTML5.fragment(response.body).at_css('turbo-stream[action="dispatchEvent"]')
        expect(JSON.parse(stream["detail"])).to eq("work_package_id" => 42)
      end
    end

    context "when the event name lacks the op-dispatched: prefix" do
      it "raises an ArgumentError" do
        expect { get :update, params: { event_name: "submit" }, as: :turbo_stream }
          .to raise_error(ArgumentError, /op-dispatched:/)
      end
    end

    context "when the event name uses the general op: namespace" do
      it "raises an ArgumentError" do
        expect { get :update, params: { event_name: "op:theme-changed" }, as: :turbo_stream }
          .to raise_error(ArgumentError)
      end
    end
  end
end
