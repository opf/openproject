# frozen_string_literal: true

require "spec_helper"
require_relative "../../db/migrate/20261102120000_add_usage_to_tm_assistant_generations"

RSpec.describe AddUsageToTmAssistantGenerations, type: :model do
  def migrate(direction) = ActiveRecord::Migration.suppress_messages { described_class.migrate(direction) }

  before { migrate(:down) }

  after do
    migrate(:up) unless ActiveRecord::Base.connection.column_exists?(:tm_assistant_generations, :usage)
    TestManagement::AssistantGeneration.reset_column_information
  end

  it "adds nullable usage jsonb" do
    expect(ActiveRecord::Base.connection.column_exists?(:tm_assistant_generations, :usage)).to be(false)

    migrate(:up)
    TestManagement::AssistantGeneration.reset_column_information

    expect(ActiveRecord::Base.connection.column_exists?(:tm_assistant_generations, :usage)).to be(true)
    expect(TestManagement::AssistantGeneration.columns_hash["usage"].type).to eq(:jsonb)
    expect(TestManagement::AssistantGeneration.columns_hash["usage"].null).to be(true)
  end
end
