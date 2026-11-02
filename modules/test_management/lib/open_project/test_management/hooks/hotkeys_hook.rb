# frozen_string_literal: true

module OpenProject::TestManagement
  module Hooks
    # Keyboard shortcuts of the module (0019): the core base layout calls
    # view_layouts_base_body_bottom on every HTML page; on pages of a project with Test management
    # this renders the shortcut config, the shortcuts dialog, the tip (Test management pages only)
    # and the nonced inline script that binds the keys. Nothing is rendered elsewhere.
    class HotkeysHook < ::OpenProject::Hook::ViewListener
      def view_layouts_base_body_bottom(context = {})
        view = context[:hook_caller]
        return "" unless view.respond_to?(:render)

        page = ::TestManagement::Hotkeys::Page.from_context(context)
        return "" unless page.active?

        view.render(partial: "test_management/hotkeys/hotkeys", locals: { page: })
      end
    end
  end
end
