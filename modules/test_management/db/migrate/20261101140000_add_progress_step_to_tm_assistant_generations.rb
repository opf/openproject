# frozen_string_literal: true

# Named generation phase for in-page polling (queued → preparing → model → writing drafts).
class AddProgressStepToTmAssistantGenerations < ActiveRecord::Migration[8.0]
  def change
    add_column :tm_assistant_generations, :progress_step, :string, limit: 32
  end
end
