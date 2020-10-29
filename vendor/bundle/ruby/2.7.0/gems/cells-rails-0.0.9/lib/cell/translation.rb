module Cell::Translation
  def self.included(includer)
    super
    includer.inheritable_attr :translation_path
  end

  def initialize(*)
    super
    @virtual_path = translation_path
  end

private
  # If you override this to change this path, please report it on the trailblazer/chat gitter channel,
  # so we can find out best practices.
  def translation_path
    self.class.translation_path or self.class.controller_path.gsub("/", ".")
  end
end
