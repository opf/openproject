require 'spec_helper'

module Redmine
  describe Themes do
    before { Themes.clear_themes }

    describe '.new_theme' do
      it "returns a new theme" do
        theme = Themes.new_theme(:new_theme)
        expect(theme).to be_kind_of Themes::Theme
        expect(theme.identifier).to eq :new_theme
      end
    end

    describe '.themes' do
      it "returns the instances of subclasses of Theme" do
        theme = Themes.new_theme
        expect(Themes.themes).to include theme
      end
    end

    describe '.clear_themes' do
      it "clears the themes" do
        theme = Themes.new_theme
        expect(Themes.themes).to_not be_empty
        Themes.clear_themes
        expect(Themes.themes).to be_empty
      end
    end

    describe '.theme' do
      it "returns a theme by name" do
        theme = Themes.new_theme(:new_theme)
        expect(Themes.theme(:new_theme)).to be theme
      end

      it "returns the default theme if theme not found" do
        expect(Themes.theme(:missing_theme)).to be Themes.default_theme
      end
    end

    describe '.default_theme' do
      it "returns the instance of the default theme class" do
        expect(Themes.default_theme).to be Themes::DefaultTheme.instance
      end
    end

    describe '.each' do
      it "iterates over the registered themes" do
        Themes.new_theme(:new_theme)
        themes = []
        Themes.each { |theme| themes << theme.identifier }
        expect(themes).to eq [:new_theme]
      end
    end

    describe '.inject' do
      it "iterates over the registered themes" do
        Themes.new_theme(:new_theme)
        identifiers = Themes.inject [] { |themes, theme| themes << theme.identifier }
        expect(identifiers).to eq [:new_theme]
      end
    end

    describe '.current_theme' do
      it "returns the theme with identifier defined by current theme identifier" do
        theme = Themes.new_theme :new_theme
        Themes.stub(:current_theme_identifier).and_return :new_theme
        expect(Themes.current_theme).to eq theme
      end

      it "returns the default theme if configured theme wasn't found" do
        Themes.stub(:current_theme_identifier).and_return :missing_theme
        expect(Themes.current_theme).to eq Themes.default_theme
      end
    end

    describe '.current_theme_identifier' do
      it "normalizes current theme setting to a symbol" do
        Setting.stub(:ui_theme).and_return 'new_theme'
        expect(Themes.current_theme_identifier).to eq :new_theme
      end

      it "returns nil for an empty string" do
        Setting.stub(:ui_theme).and_return ''
        expect(Themes.current_theme_identifier).to be_nil
      end

      it "returns nil for nil" do
        Setting.stub(:ui_theme).and_return nil
        expect(Themes.current_theme_identifier).to be_nil
      end
    end
  end
end
