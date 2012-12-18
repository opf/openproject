require 'spec_helper'

module Redmine
  module Themes
    describe Theme do
      before { Theme.clear }

      describe '.new_theme' do
        it "returns a new theme" do
          theme = Theme.new_theme
          expect(theme).to be_kind_of Theme
        end

        it "allows passing in the identifier" do
          theme = Theme.new_theme(:new_theme)
          expect(theme.identifier).to eq :new_theme
        end
      end

      describe '.themes' do
        it "returns all instances of descendants of themes" do
          theme = Theme.new_theme
          expect(Theme.themes).to include theme
        end

        # the before filter above removes the default theme as well. to test
        # the correct behaviour we just spec that the default theme class
        # was loaded (by looking through all subclasses of BasicObject)
        it "always includes the default theme" do
          loaded_classes = Object.descendants
          expect(loaded_classes).to include Themes::DefaultTheme
        end

        # test through the theme instances classes because
        # an abstract theme can't have an instance
        it "filters out themes marked as abstract" do
          theme_class = Class.new(Theme) { abstract! }
          theme_classes = Theme.themes.map(&:class)
          expect(theme_classes).to_not include theme_class
        end

        it "subclasses of abstract themes aren't abstract by default" do
          abstract_theme_class = Class.new(Theme) { abstract! }
          child_theme_class = Class.new(abstract_theme_class)
          expect(Theme.themes).to include child_theme_class.instance
        end
      end
      
      describe '.registered_themes' do
        it "returns a hash of themes if their identifiers as keys" do
          theme = Theme.new_theme(:new_theme)
          expect(Theme.registered_themes).to include :new_theme => theme
        end
      end

      describe '.abstract!' do
        it "marks the theme class as abstract" do
          theme_class = Class.new(Theme) { abstract! }
          expect(Theme.abstract_themes).to include theme_class
        end

        it "the basic theme class is abstract" do
          expect(Theme.abstract_themes).to include Theme
        end

        it "abstract themes have no instance" do
          theme_class = Class.new(Theme) { abstract! }
          expect { theme_class.instance }.to raise_error NoMethodError
        end
      end

      describe '.abstract?' do
        it "is abstract when marked as abstract" do
          theme_class = Class.new(Theme)
          expect(theme_class).to_not be_abstract
          theme_class.abstract!
          expect(theme_class).to be_abstract
        end
      end

      describe '.descendants' do
        it "it rememberes all classes that descend from Theme" do
          theme_class = Class.new(Theme)
          expect(Theme.descendants).to include theme_class
        end

        it "it works on multiple levels" do
          theme_class = Class.new(Class.new(Theme))
          expect(Theme.descendants).to include theme_class
        end
      end

      describe '.clear' do
        it "it wipes out all remembered descendants" do
          theme_class = Class.new(Theme)
          Theme.clear
          expect(Theme.descendants).to be_empty
        end
      end

      describe '.instance' do
        it "is an instance of the class" do
          theme_class = Class.new(Theme)
          expect(theme_class.instance.class).to be theme_class
        end

        it "is a singleton" do
          theme_class = Class.new(Theme)
          expect(theme_class.instance).to be theme_class.instance
        end
      end

      describe '.inherited' do
        it "it is aware of the new theme (clears the cache when subclassing)" do
          Theme.themes
          theme = Theme.new_theme
          expect(Theme.themes).to include theme
        end
      end

      describe '.each' do
        it "iterates over all themes" do
          Theme.new_theme(:new_theme)
          themes = []
          Theme.each { |theme| themes << theme.identifier }
          expect(themes).to eq [:new_theme]
        end
      end
      
      describe '#assets_path' do
        it "should raise exception telling it is sublass responsibility" do
          theme = Theme.new_theme(:new_theme)
          expect { theme.assets_path }.to raise_error Theme::SubclassResponsibility
        end
      end

      describe '#overridden_images' do
        let(:theme) { Theme.new_theme }

        context 'with correct path' do
          before do
            # set the dir of this file as the images folder
            theme.stub(:overridden_images_path).and_return(File.dirname(__FILE__))
          end

          it 'stores images that are overridden by the theme' do
            expect(theme.overridden_images).to include 'theme_spec.rb'
          end

          it "doesn't store images which are not present" do
            expect(theme.overridden_images).to_not include 'missing.rb'
          end
        end

        context 'with incorrect path' do
          before do
            # the theme has a non-existing images path
            theme.stub(:overridden_images_path).and_return('some/wrong/path')
          end

          it 'wont fail' do
            expect { theme.overridden_images }.to_not raise_error Errno::ENOENT
          end

          it 'has an empty list' do
            expect(theme.overridden_images).to be_empty
          end
        end
      end

      describe '#path_to_image' do
        let(:theme) { Theme.new_theme(:new_theme) }

        before do
          # set a list of overridden images
          theme.stub(:overridden_images).and_return(['add.png'])
        end

        it "prepends the theme path if file is present" do
          expect(theme.path_to_image('add.png')).to eq 'new_theme/add.png'
        end

        it "doesn't prepend the theme path if the file is not overridden" do
          expect(theme.path_to_image('missing.png')).to eq 'missing.png'
        end

        it "doesn't change anything if the path is absolute" do
          expect(theme.path_to_image('/add.png')).to eq '/add.png'
        end

        it "doesn't change anything if the source is a url" do
          expect(theme.path_to_image('http://some_host/add.png')).to eq 'http://some_host/add.png'
        end
      end

      describe '#overridden_images_path' do
        let(:theme) { Theme.new_theme(:new_theme) }

        before do
          # set an arbitrary base path for assets
          theme.stub(:assets_path).and_return('some/assets/path')
        end

        it 'appends the path to images overridden by the theme' do
          expect(theme.overridden_images_path).to eq 'some/assets/path/images/new_theme'
        end
      end

      describe '#image_overridden?' do
        let(:theme) { Theme.new_theme }

        before do
          # set the dir of this file as the images folder
          theme.stub(:overridden_images_path).and_return(File.dirname(__FILE__))
        end

        it 'is overritten if the theme redefines it' do
          expect(theme.image_overridden?('theme_spec.rb')).to be_true
        end

        it "is not overritten if the theme doesn't redefine it" do
          expect(theme.image_overridden?('missing.rb')).to be_false
        end
      end

      describe '#stylesheet_manifest' do
        it 'equals the name of the theme with a css extension' do
          theme = Theme.new_theme(:new_theme)
          expect(theme.stylesheet_manifest).to eq 'new_theme.css'
        end
      end

      describe '#assets_prefix' do
        it 'equals the name of the theme' do
          theme = Theme.new_theme(:new_theme)
          expect(theme.assets_prefix).to eq 'new_theme'
        end
      end

      describe '#<=>' do
        it "is equal when the classes match" do
          theme_class = Class.new(Theme)
          expect(theme_class.instance).to eq theme_class.instance
        end

        it "is not equal when the classes don't match" do
          expect(Class.new(Theme).instance).to_not eq Class.new(Theme).instance
        end
      end

      describe '#default?' do
        it "returns false" do
          expect(Theme.new_theme).to_not be_default
        end
      end
    end

    describe ViewHelpers do
      let(:theme)   { Theme.new_theme(:new_theme) }
      let(:helpers) { ApplicationController.helpers }

      before do
        # set a list of overridden images
        theme.stub(:overridden_images).and_return(['add.png'])

        # set the theme as current
        helpers.stub(:current_theme).and_return(theme)
      end

      it 'overridden images are nested' do
        expect(helpers.image_tag('add.png')).to include 'src="/assets/new_theme/add.png"'
      end

      it 'not overridden images are on root level' do
        expect(helpers.image_tag('missing.png')).to include 'src="/assets/missing.png"'
      end

      it 'overridden favicon is nested' do
        expect(helpers.favicon_link_tag('add.png')).to include 'href="/assets/new_theme/add.png"'
      end

      it 'not overridden favicon is on root level' do
        expect(helpers.favicon_link_tag('missing.png')).to include 'href="/assets/missing.png"'
      end
    end
  end
end
