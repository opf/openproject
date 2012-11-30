require 'spec_helper'

module Redmine
  describe Themes do
    before do
      Themes.clear
    end
    
    describe '#new_theme' do
      it "returns a new theme" do
        expected = Themes::Theme.new(:some_name)

        theme = Themes.new_theme :some_name
        expect(theme).to eq expected
      end
    end
    
    describe '#register' do
      it "registers themes" do
        theme = Themes.new_theme :some_name
        Themes.register theme
        expect(Themes.themes).to include theme
      end

      it "registers themes by name" do
        expected = Themes.new_theme :some_name

        Themes.register :some_name
        expect(Themes.themes).to include expected
      end

      it "registers multiple themes at once" do
        theme_1 = Themes.new_theme :some_name
        theme_2 = Themes.new_theme :some_other_name

        Themes.register :some_name, :some_other_name
        expect(Themes.themes).to include theme_1
        expect(Themes.themes).to include theme_2
      end

      it "does not store duplicate themes" do
        Themes.register :some_name, :some_name
        expect(Themes.themes.size).to eq 1
      end
      
      it "returns registered themes" do
        expected = Themes.new_theme :some_name

        themes = Themes.register :some_name
        expect(themes).to eq [expected]
      end
    end

    describe '#themes' do
      it "returns all themes as an array" do
        expected = Themes.new_theme :some_name
        
        Themes.register :some_name
        expect(Themes.themes).to eq [expected]
      end
    end

    describe '#all' do
      it "returns all themes as an array (same as #themes)" do
        expected = Themes.new_theme :some_name
        
        Themes.register :some_name
        expect(Themes.themes).to eq [expected]
      end
    end

    describe '#theme' do
      it "returns a theme by name" do
        theme = Themes.new_theme :some_name
        Themes.register theme
        expect(Themes.theme(:some_name)).to eq theme
      end

      it "returns a default theme if not found" do
        theme = Themes.new_theme :some_name
        Themes.stub(:default_theme).and_return(theme)
        expect(Themes.theme(:some_missing_name)).to be theme
      end
    end

    describe '#find_theme' do
      it "returns a theme by name" do
        theme = Themes.new_theme :some_name
        Themes.register theme
        expect(Themes.find_theme(:some_name)).to eq theme
      end

      it "returns nil if no theme found" do
        theme = Themes.new_theme :some_name
        Themes.register theme
        expect(Themes.find_theme(:some_other_name)).to be_nil
      end
    end

    describe '#clear' do
      it "clears out the themes list" do
        Themes.register :some_name
        Themes.clear
        expect(Themes.themes).to be_empty
      end
    end
    
    describe '#default_theme' do
      it 'delagates to Theme class' do
        expect(Themes.default_theme).to be Themes::Theme.default
      end

      it 'defines the default theme' do
        theme = Themes.new_theme :some_name
        Themes.stub(:default_theme).and_return(theme)
        expect(Themes.default_theme).to be theme
      end
    end
    
    describe '#register_default_theme' do
      it "registers the default theme" do
        Themes.register_default_theme
        expect(Themes.all).to include Themes.default_theme
      end
      
      it 'always registers the default theme on load' do
        # reload the file because we called Themes.clear in the before block
        # maybe better: skip the before block for this example?!
        load File.expand_path('../../../lib/redmine/themes.rb', __FILE__)

        expect(Themes.all).to include Themes.default_theme
      end
    end
    
    describe '#each' do
      it 'iterates over the registered themes' do
        Themes.register :some_name
        themes = []
        Themes.each { |theme| themes << theme.name }
        expect(themes).to eq [:some_name]
      end
    end
    
    describe '#inject' do
      it 'iterates over the registered themes' do
        Themes.register :some_name
        names = Themes.inject [] { |themes, theme| themes << theme.name }
        expect(names).to eq [:some_name]
      end
    end
  end
end