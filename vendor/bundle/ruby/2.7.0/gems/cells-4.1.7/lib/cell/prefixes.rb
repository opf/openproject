module Cell::Prefixes
  def self.included(includer)
    includer.extend(ClassMethods)
  end

  def _prefixes
    self.class.prefixes
  end

  # You're free to override those methods in case you want to alter our view inheritance.
  module ClassMethods
    def prefixes
      @prefixes ||= _prefixes
    end

  private
    def _prefixes
      return [] if abstract?
      _local_prefixes + superclass.prefixes
    end

    def _local_prefixes
      view_paths.collect { |path| "#{path}/#{controller_path}" }
    end

    # Instructs Cells to inherit views from a parent cell without having to inherit class code.
    def inherit_views(parent)
      define_method :_prefixes do
        super() + parent.prefixes
      end
    end
  end
end