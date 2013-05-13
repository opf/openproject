##
# From Urban Dictionary:
#   proactive (91 up, 9 down)
# 
#   Originally a psychological term indicating an empowered, self-reliant
#   individual, this has evolved through misuse into a neo-antonym of 'reactive',
#   and is used as such to emphasise the preferability of one attitude or course
#   of action over another. It connotes alertness, awareness and preparedness, and
#   seeks to dispel any conceivable impression of incompetence.
# 
#   'Proactive' is interesting in that it is perhaps the classic example of the
#   unnecessary neologism. It serves as an antonym to 'reactive', yet 'reactive'
#   is itself the antonym of 'active'.
# 
#   Arguably, since 'proactive' is now perhaps more widely used than 'active' for
#   the specific purpose covered by the newer word, 'proactive' must be recognised
#   as a legitimate word. The cult of hatred that has understandably grown up
#   around the word can only help it endure further.
# 
#   One is 'active' as opposed to being 'passive' or 'reactive'. One is
#   'proactive' as opposed to 'speaking English'.
module ProactiveAutoloader
  extend self

  ##
  # Improved Module#autoload:
  # * if path is not given, generate path according to ruby common sense
  # * allow passing multiple constant names as symbols
  #
  # Example:
  #   autoload :Foo, :Bar, :Blah
  def autoload(*list)
    return super if list.size == 2 and String === list.last
    list.each do |const|
      super const, "#{name.underscore}/#{const.to_s.underscore}"
    end
  end

  ##
  # Sets up autoload hooks in +klass+ for all Ruby files in +dir+, following
  # common naming conventions. Subdirectories are *not* scanned.
  def setup_autoloaders(klass, dir)
    Dir.glob File.expand_path('*.rb', dir) do |file|
      klass.autoload File.basename(file, '.rb').camelize, file
    end
  end

  ##
  # If subclassed, say in foo/bar.rb and there is a directory foo/bar,
  # set up autoload hooks in subclass for all ruby files in foo/bar
  # (see setup_autoloaders).
  def inherited(klass)
    auto_setup_autoloaders(klass)
    super
  end

  ##
  # If extending a class, say in foo/bar.rb and there is a directory foo/bar,
  # set up autoload hooks in subclass for all ruby files in foo/bar
  # (see setup_autoloaders).
  def self.extended(klass)
    auto_setup_autoloaders(klass) if klass.respond_to? :autoload
    super
  end
  
  private
  
  def auto_setup_autoloaders(klass)
    setup_autoloaders klass, caller[1][/^((?!\.[^\.]+:\d+).)+/]
  end
end
