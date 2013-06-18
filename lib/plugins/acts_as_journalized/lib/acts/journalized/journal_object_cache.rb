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

module Acts
  module Journalized
    class JournalObjectCache
      # unloadable

      def fetch(klass, id, &block)

        @cache ||= Hash.new do |klass_hash, klass_key|
          klass_hash[klass_key] = Hash.new do |id_hash, id_key|
                                    id_hash[id_key] = yield klass_key, id_key
                                  end
        end

        @cache[klass][id]
      end
    end
  end
end
