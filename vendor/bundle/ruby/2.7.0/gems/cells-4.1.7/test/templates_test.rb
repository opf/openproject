require 'test_helper'


class TemplatesTest < MiniTest::Spec
  Templates = Cell::Templates

  # existing.
  it { Templates.new[['test/fixtures/bassist'], 'play.erb', {template_class: Cell::Erb::Template}].file.must_equal 'test/fixtures/bassist/play.erb' }

  # not existing.
  it { assert_nil(Templates.new[['test/fixtures/bassist'], 'not-here.erb', {}]) }


  # different caches for different classes

  # same cache for subclasses

end


class TemplatesCachingTest < MiniTest::Spec
  class SongCell < Cell::ViewModel
    self.view_paths = ['test/fixtures']
    # include Cell::Erb

    def show
      render
    end
  end

  # templates are cached once and forever.
  it do
    cell = cell("templates_caching_test/song")

    cell.call(:show).must_equal 'The Great Mind Eraser'

    SongCell.templates.instance_eval do
      def create; raise; end
    end

    # cached, NO new tilt template.
    cell.call(:show).must_equal 'The Great Mind Eraser'
  end
end
