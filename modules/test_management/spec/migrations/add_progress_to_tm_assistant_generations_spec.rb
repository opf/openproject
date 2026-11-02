# frozen_string_literal: true

require "spec_helper"
require_relative "../../db/migrate/20261031210000_add_progress_to_tm_assistant_generations"

RSpec.describe AddProgressToTmAssistantGenerations, type: :model do
  def migrate(direction) = ActiveRecord::Migration.suppress_messages { described_class.migrate(direction) }

  before { migrate(:down) }

  after do
    migrate(:up) unless ActiveRecord::Base.connection.column_exists?(:tm_assistant_generations, :progress_done)
    TestManagement::AssistantGeneration.reset_column_information
  end

  it "adds nullable progress_done and progress_total" do
    expect(ActiveRecord::Base.connection.column_exists?(:tm_assistant_generations, :progress_done)).to be(false)

    migrate(:up)
    TestManagement::AssistantGeneration.reset_column_information

    expect(ActiveRecord::Base.connection.column_exists?(:tm_assistant_generations, :progress_done)).to be(true)
    expect(ActiveRecord::Base.connection.column_exists?(:tm_assistant_generations, :progress_total)).to be(true)
    expect(TestManagement::AssistantGeneration.columns_hash["progress_done"].null).to be(true)
    expect(TestManagement::AssistantGeneration.columns_hash["progress_total"].null).to be(true)
  end
end
