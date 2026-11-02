# frozen_string_literal: true

# Draft generation progress for in-page polling (progress bar / "3 of 6").
class AddProgressToTmAssistantGenerations < ActiveRecord::Migration[8.0]
  def change
    change_table :tm_assistant_generations, bulk: true do |t|
      t.integer :progress_done
      t.integer :progress_total
    end
  end
end
