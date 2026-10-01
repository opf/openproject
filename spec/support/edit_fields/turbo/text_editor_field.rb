# frozen_string_literal: true

require_relative "../text_editor_field"

module Turbo
  class TextEditorField < ::TextEditorField
    def display_selector
      page.test_selector("op-inplace-edit-field")
    end

    def control_link(action = :save)
      raise "Invalid link" unless %i[save cancel].include?(action)

      "#{page.test_selector("op-inplace-edit-field--textarea-#{action}")}:not([disabled])"
    end
  end
end
