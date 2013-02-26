module Acts
  module Journalized
    class JournalObjectCache
      unloadable

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
