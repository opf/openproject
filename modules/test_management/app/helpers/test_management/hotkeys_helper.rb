# frozen_string_literal: true

module TestManagement
  # <kbd> badges for the shortcuts of the module (0019) on buttons of Test management pages.
  module HotkeysHelper
    def tm_hotkeys_page(project)
      TestManagement::Hotkeys::Page.from_context({ project:, controller: })
    end

    # Badge for a shortcut, nil when badges are off (admin, user, "Disable keyboard shortcuts") or the
    # shortcut is not available to the user.
    def tm_hotkey_kbd(id, project:)
      page = tm_hotkeys_page(project)
      keys = page.keys_for(id)
      return if keys.nil? || !page.hints?

      content_tag(:kbd, keys,
                  class: "tm-kbd",
                  title: t("test_management.hotkeys.badge_title", keys:),
                  "aria-hidden": true,
                  data: { test_selector: "tm-hotkey-badge-#{id}" })
    end
  end
end
