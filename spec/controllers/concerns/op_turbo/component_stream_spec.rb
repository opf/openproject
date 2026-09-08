# frozen_string_literal: true

require "rails_helper"

RSpec.describe OpTurbo::ComponentStream do
  described_module = described_class

  controller(ApplicationController) do
    include described_module

    no_authorization_required! :update, :set_page_title

    def update
      dispatch_event_via_turbo_stream(params[:event_name], detail: { work_package_id: 42 })
      respond_to_with_turbo_streams
    end

    def set_page_title
      project = Project.new(name: params[:project_name]) if params[:project_name].present?
      set_page_title_via_turbo_stream(*params[:parts], project:)
      respond_to_with_turbo_streams
    end
  end

  current_user { build_stubbed(:user) }

  before do
    routes.draw do
      get "update" => "anonymous#update"
      get "set_page_title" => "anonymous#set_page_title"
    end
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

  describe "#set_page_title_via_turbo_stream" do
    subject(:rendered_title) do
      Nokogiri::HTML5.fragment(response.body).at_css('turbo-stream[action="set_title"]')&.[]("title")
    end

    it "renders the title a full page load of the same parts would produce" do
      get :set_page_title, params: { parts: ["Documents", "Renamed document"], project_name: "Demo project" },
                           as: :turbo_stream

      expect(response.body).to have_turbo_stream(action: "set_title")
      expect(rendered_title).to eq("Renamed document | Documents | Demo project | #{Setting.app_title}")
    end

    it "omits the project segment outside of a project context" do
      get :set_page_title, params: { parts: ["My account"] }, as: :turbo_stream

      expect(rendered_title).to eq("My account | #{Setting.app_title}")
    end

    it "does not emit empty segments" do
      get :set_page_title, params: { parts: ["Documents", ""] }, as: :turbo_stream

      expect(rendered_title).to eq("Documents | #{Setting.app_title}")
    end
  end
end
