# frozen_string_literal: true

require "spec_helper"
require_relative "../../db/migrate/20261101140000_add_progress_step_to_tm_assistant_generations"

RSpec.describe AddProgressStepToTmAssistantGenerations, type: :model do
  def migrate(direction) = ActiveRecord::Migration.suppress_messages { described_class.migrate(direction) }

  before { migrate(:down) }

  after do
    migrate(:up) unless ActiveRecord::Base.connection.column_exists?(:tm_assistant_generations, :progress_step)
    TestManagement::AssistantGeneration.reset_column_information
  end

  it "adds nullable progress_step" do
    expect(ActiveRecord::Base.connection.column_exists?(:tm_assistant_generations, :progress_step)).to be(false)

    migrate(:up)
    TestManagement::AssistantGeneration.reset_column_information

    expect(ActiveRecord::Base.connection.column_exists?(:tm_assistant_generations, :progress_step)).to be(true)
    expect(TestManagement::AssistantGeneration.columns_hash["progress_step"].null).to be(true)
  end
end
