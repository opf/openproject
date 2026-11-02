# frozen_string_literal: true

module TestManagement
  # Keyboard shortcuts of the Test management module (0019). Plain letter sequences in the style of
  # core OpenProject ("g w p" = go to work packages, "n w p" = new work package), "t" being the
  # module letter. The bindings run in a small inline script (no frontend rebuild), see
  # app/views/test_management/hotkeys/_hotkeys.html.erb; TestManagement::Hotkeys::Page decides per
  # request which ones the current user gets and where they lead.
  module Hotkeys
    Shortcut = Data.define(:id, :keys, :scope) do
      # "g t c" -> %w[g t c]
      def sequence
        keys.split
      end

      # Only on Test management pages (true) or on every page of a project with the module (false).
      def module_only?
        scope == :module
      end
    end

    SHORTCUTS = [
      Shortcut.new(id: "cases", keys: "g t c", scope: :project),
      Shortcut.new(id: "runs", keys: "g t r", scope: :project),
      Shortcut.new(id: "assistant", keys: "g t a", scope: :project),
      Shortcut.new(id: "new_case", keys: "n t c", scope: :project),
      Shortcut.new(id: "new_run", keys: "n t r", scope: :project),
      Shortcut.new(id: "up", keys: "u", scope: :module),
      Shortcut.new(id: "help", keys: "g t h", scope: :project)
    ].freeze

    # Sequences bound by core (frontend/src/app/shared/directives/a11y/keyboard-shortcut.service.ts)
    # plus "g t" (Timelines), which the user guide still lists although nothing binds it any more.
    CORE_SEQUENCES = [
      "?", "s", "p", "m", "j", "k",
      "g m", "g o", "g w p", "g w i", "g a", "g c", "g n", "g e", "g p", "g t",
      "n w p", "d w p"
    ].freeze

    # Core single-key shortcuts. Core's Mousetrap also sees our keys: after "g" a key that does not
    # continue a core sequence resets it and is then handled as a single key, so none of these may
    # appear anywhere in a TM sequence ("g t m" would open core's "More" menu).
    CORE_SINGLE_KEYS = CORE_SEQUENCES.reject { |seq| seq.include?(" ") }.freeze

    # Keys owned by the browser, editors or the OS: Backspace (text deletion / old "history back"),
    # "/" and "'" (Firefox quick find), digits (access keys use Alt/Ctrl+Opt + digit).
    RESERVED_KEYS = ["/", "'", "backspace", "delete", *("0".."9")].freeze

    # Core sequences that are actually bound; "g t" is documented only, so a three-key "g t x" is
    # accepted as long as "g t" itself stays unbound (see conflicts_with_core).
    DOCUMENTED_ONLY = ["g t"].freeze

    TIP_PROBABILITY = 0.35
    TIP_COOLDOWN_MINUTES = 10
    SEQUENCE_TIMEOUT_MS = 1000

    module_function

    def find(id)
      SHORTCUTS.find { |shortcut| shortcut.id == id.to_s }
    end

    # Conflicts of one sequence with core and the browser, as human readable strings (empty = OK).
    def conflicts_for(keys)
      seq = keys.to_s.split
      problems = []
      return ["empty"] if seq.empty?

      if (bad = seq.find { |key| key.length != 1 || key.match?(/[^a-z]/) })
        problems << "#{keys}: '#{bad}' is not a plain lower-case letter"
      end
      seq.each do |key|
        problems << "#{keys}: '#{key}' is reserved by the browser" if RESERVED_KEYS.include?(key)
        problems << "#{keys}: '#{key}' is a core single-key shortcut" if CORE_SINGLE_KEYS.include?(key)
      end
      (CORE_SEQUENCES - CORE_SINGLE_KEYS - DOCUMENTED_ONLY).each do |core|
        core_seq = core.split
        if seq == core_seq
          problems << "#{keys}: equals core '#{core}'"
        elsif seq.first(core_seq.length) == core_seq
          problems << "#{keys}: starts with core '#{core}' (core fires first)"
        elsif core_seq.first(seq.length) == seq
          problems << "#{keys}: is a prefix of core '#{core}'"
        elsif seq.length > 2 && core_seq.length > 2 && seq.first(2) == core_seq.first(2)
          problems << "#{keys}: shares the core prefix '#{core_seq.first(2).join(' ')}'"
        end
      end
      problems << "#{keys}: equals documented core '#{keys}'" if DOCUMENTED_ONLY.include?(keys.to_s)
      problems.uniq
    end

    # Conflicts of the whole TM mapping: with core and the browser, and within the module (no
    # sequence may be a prefix of another one).
    def conflicts
      own = SHORTCUTS.flat_map { |shortcut| conflicts_for(shortcut.keys) }
      SHORTCUTS.combination(2).each do |a, b|
        short, long = [a.sequence, b.sequence].sort_by(&:length)
        own << "#{a.keys} / #{b.keys}: one is a prefix of the other" if long.first(short.length) == short
      end
      own
    end

    def settings
      Hash(Setting.plugin_openproject_test_management).with_indifferent_access
    end

    # Administration > Test management > Keyboard shortcuts (plugin settings, on by default).
    def enabled?
      setting_on?(:hotkeys_enabled)
    end

    def hints_enabled?
      enabled? && setting_on?(:hotkey_hints_enabled)
    end

    def setting_on?(key)
      value = settings[key]
      value.nil? || ActiveModel::Type::Boolean.new.cast(value) != false
    end
  end
end
