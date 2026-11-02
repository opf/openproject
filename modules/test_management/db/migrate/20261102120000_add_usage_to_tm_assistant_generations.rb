# frozen_string_literal: true

# Token usage returned by the AI provider for a completed Generate job (prompt / completion /
# total, optional reasoning). Captured from the chat-completion response; nil until done.
class AddUsageToTmAssistantGenerations < ActiveRecord::Migration[8.0]
  def change
    add_column :tm_assistant_generations, :usage, :jsonb
  end
end
