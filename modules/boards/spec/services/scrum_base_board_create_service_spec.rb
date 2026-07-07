# frozen_string_literal: true

require "spec_helper"
require_relative "base_create_service_shared_examples"

RSpec.describe Boards::ScrumBaseBoardCreateService do
  shared_let(:project) { create(:project) }
  shared_let(:status) { create(:default_status) }
  shared_let(:user) { build_stubbed(:admin) }
  shared_let(:instance) { described_class.new(user:) }

  subject { instance.call(params) }

  context "with all valid params" do
    let(:params) do
      {
        name: "Scrum Base Board",
        project:,
        attribute: "scrum_base"
      }
    end

    it "is successful" do
      expect(subject).to be_success
    end

    it 'creates a "Scrum Base" action board', :aggregate_failures do
      board = subject.result

      expect(board.name).to eq("Scrum Base Board")
      expect(board.options[:attribute]).to eq("scrum_base")
      expect(board.options[:type]).to eq("action")
      expect(board.board_type).to eq(:action)
      expect(board.board_type_attribute).to eq("scrum_base")
    end

    describe "widgets and queries" do
      let(:board) { subject.result }
      let(:widgets) { board.widgets }
      let(:queries) { Query.all }

      it "creates one of each for the current default status", :aggregate_failures do
        subject

        expect(widgets.count).to eq 1
        expect(queries.count).to eq 1
      end

      it "filters the column by status, like a status board" do
        subject

        query_filter = queries.flat_map(&:filters).map(&:to_hash).first
        widget_filter = widgets.flat_map { it.options["filters"] }.first

        expect(query_filter).to match_array(widget_filter)
        # the single column filter is a status filter (status_id): the Scrum Base board's
        # columns are statuses, just like the Status board
        expect(widget_filter.keys.map(&:to_s)).to include("status_id")
      end

      it_behaves_like "sets the appropriate sort_criteria on each query"
    end
  end
end
