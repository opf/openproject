require "cell/self_contained"

module Cell
  # Cell::Concept is no longer under active development. Please switch to Trailblazer::Cell.
  class Concept < Cell::ViewModel
    abstract!
    self.view_paths = ["app/concepts"]
    extend SelfContained

    # TODO: this should be in Helper or something. this should be the only entry point from controller/view.
    class << self
      def class_from_cell_name(name)
        util.constant_for(name)
      end

      def controller_path
        @controller_path ||= util.underscore(name.sub(/(::Cell$|Cell::)/, ''))
      end
    end

    alias_method :concept, :cell

    self_contained!
  end
end
