require 'spec_helper'

module Redmine
  module Themes
    describe Theme do
      before do
        Theme.forget_default_theme
      end

      describe '#initialize' do
        it 'stores the name' do
          theme = Theme.new(:some_name)
          expect(theme.name).to eq :some_name
        end
      end
      
      describe '#from' do
        it 'returns self when given a theme' do
          theme = Theme.new(:some_name)
          expect(Theme.from(theme)).to eq theme
        end

        it 'returns a new theme given a name' do
          expected = Theme.new(:some_name)

          theme = Theme.from(:some_name)
          expect(theme).to eq expected
        end
      end
      
      describe '#default' do
        it 'returns the default theme' do
          expect(Theme.default).to be_default
        end
        
        it 'always returns the same theme' do
          expect(Theme.default).to be Theme.default
        end
      end
      
      describe '#default?' do
        it 'returns true if it really is the default theme' do
          theme = Theme.new(:some_name)
          Theme.stub(:default).and_return(theme)
          expect(theme).to be_default
        end
        
        it 'returns false if it is not the default theme' do
          theme = Theme.new(:some_name)
          expect(theme).to_not be_default
        end
      end

      describe '#default_theme_name' do
        it 'has a default theme name of :default' do
          expect(Theme.default.name).to eq :default
        end

        it 'defines the name of the default theme' do
          Theme.stub(:default_theme_name).and_return(:some_default_name)
          expect(Theme.default.name).to eq :some_default_name
        end
      end
      
      describe '#forget_default_theme' do
        it 'will clear the old default theme' do
          theme = Theme.default
          Theme.forget_default_theme
          expect(Theme.default).to_not be theme
        end
      end
      
      describe '#main_stylesheet_path' do
        it 'equals the name of the theme' do
          theme = Theme.new(:some_name)
          expect(theme.main_stylesheet_path).to eq 'some_name'
        end
      end

      describe '#favicon_path' do
        it 'is on the root level for the default theme' do
          theme = Theme.default
          expect(theme.favicon_path).to eq '/favicon.ico'
        end

        it "prepends the theme name unless it's the default theme" do
          theme = Theme.new(:some_name)
          expect(theme.favicon_path).to eq '/some_name/favicon.ico'
        end
      end
      
      describe '#<=>' do
        it "is equal when the names match" do
          expect(Theme.new(:some_name)).to eq Theme.new(:some_name)
        end

        it "is not equal when the names don't match" do
          expect(Theme.new(:some_name)).to_not eq Theme.new(:some_other_name)
        end
        
        it "doesn't make a difference between strings and symbols" do
          expect(Theme.new(:some_name)).to eq Theme.new('some_name')
        end
      end
    end
  end
end
