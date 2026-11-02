# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::Hotkeys do
  describe "mapping" do
    it "has the agreed sequences" do
      expect(described_class::SHORTCUTS.to_h { |shortcut| [shortcut.id, shortcut.keys] }).to eq(
        "cases" => "g t c", "runs" => "g t r", "assistant" => "g t a",
        "new_case" => "n t c", "new_run" => "n t r", "up" => "u", "help" => "g t h"
      )
    end

    it "conflicts neither with core shortcuts, browser keys nor itself" do
      expect(described_class.conflicts).to eq([])
    end

    it "uses no Backspace, Ctrl+B or any modifier" do
      keys = described_class::SHORTCUTS.flat_map(&:sequence)
      expect(keys).to all(match(/\A[a-z]\z/))
      expect(keys).not_to include("backspace")
    end

    it "only binds 'up' on Test management pages" do
      expect(described_class::SHORTCUTS.select(&:module_only?).map(&:id)).to eq(%w[up])
    end

    it "has a label for every shortcut and a tip for every shortcut except the list" do
      described_class::SHORTCUTS.each do |shortcut|
        expect(I18n.t("test_management.hotkeys.actions.#{shortcut.id}", default: nil)).to be_present
        next if shortcut.id == "help"

        expect(I18n.t("test_management.hotkeys.tips.#{shortcut.id}_html", keys: "x", default: nil)).to include("x")
      end
    end
  end

  describe ".conflicts_for" do
    it "rejects core sequences, their prefixes and extensions" do
      expect(described_class.conflicts_for("g w p")).to include(include("equals core"))
      expect(described_class.conflicts_for("g")).to include(include("prefix of core"))
      expect(described_class.conflicts_for("n w p x")).to include(include("starts with core"))
      expect(described_class.conflicts_for("g w x")).to include(include("shares the core prefix"))
    end

    it "rejects core single keys in any position (core's handler sees our keys too)" do
      expect(described_class.conflicts_for("g t m")).to include(include("'m' is a core single-key"))
      expect(described_class.conflicts_for("s")).to include(include("'s' is a core single-key"))
      expect(described_class.conflicts_for("g t j")).to include(include("'j' is a core single-key"))
    end

    it "rejects browser keys and the documented 'g t'" do
      expect(described_class.conflicts_for("/")).to be_present
      expect(described_class.conflicts_for("u 1")).to be_present
      expect(described_class.conflicts_for("g t")).to include(include("documented core"))
    end

    it "accepts free sequences" do
      expect(described_class.conflicts_for("g t z")).to eq([])
      expect(described_class.conflicts_for("u")).to eq([])
    end
  end

  describe "admin switches" do
    def with_plugin_settings(values)
      allow(Setting).to receive(:plugin_openproject_test_management).and_return(values)
    end

    it "is on by default" do
      with_plugin_settings({})
      expect(described_class).to be_enabled
      expect(described_class).to be_hints_enabled
    end

    it "can switch off the hints only" do
      with_plugin_settings("hotkey_hints_enabled" => false)
      expect(described_class).to be_enabled
      expect(described_class).not_to be_hints_enabled
    end

    it "switches off the hints with the shortcuts" do
      with_plugin_settings("hotkeys_enabled" => "0", "hotkey_hints_enabled" => true)
      expect(described_class).not_to be_enabled
      expect(described_class).not_to be_hints_enabled
    end
  end
end
