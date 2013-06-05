#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module I18nPatch
  module ClassMethods
    # Executes block without fallback locales set.
    def without_fallbacks
      current_fallbacks = self.fallbacks[self.locale]
      self.fallbacks[self.locale] = [self.locale]
      yield
    ensure
      self.fallbacks[self.locale] = current_fallbacks
    end
  end

  module InstanceMethods
  end

  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end
end

I18n.send(:include, I18nPatch)
