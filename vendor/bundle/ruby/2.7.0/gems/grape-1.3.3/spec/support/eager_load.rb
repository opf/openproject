# frozen_string_literal: true

# Grape uses autoload https://api.rubyonrails.org/classes/ActiveSupport/Autoload.html.
# When a class/module get added to the list, ActiveSupport doesn't check whether it really exists.
# This method loads all classes/modules defined via autoload to be sure only existing
# classes/modules were listed.
def eager_load!(scope = Grape)
  # get modules
  scope.constants.each do |const_name|
    const = scope.const_get(const_name)

    next unless const.respond_to?(:eager_load!)

    const.eager_load!

    # check its modules, they might need to be loaded as well.
    eager_load!(const)
  end
end
