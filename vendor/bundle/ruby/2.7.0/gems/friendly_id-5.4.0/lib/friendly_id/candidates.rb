require 'securerandom'

module FriendlyId

  # This class provides the slug candidate functionality.
  # @see FriendlyId::Slugged
  class Candidates

    include Enumerable

    def initialize(object, *array)
      @object = object
      @raw_candidates = to_candidate_array(object, array.flatten(1))
    end

    def each(*args, &block)
      return candidates unless block_given?
      candidates.each{ |candidate| yield candidate }
    end

    private

    def candidates
      @candidates ||= begin
        candidates = normalize(@raw_candidates)
        filter(candidates)
      end
    end

    def normalize(candidates)
      candidates.map do |candidate|
        @object.normalize_friendly_id(candidate.map(&:call).join(' '))
      end.select {|x| wanted?(x)}
    end

    def filter(candidates)
      unless candidates.all? {|x| reserved?(x)}
        candidates.reject! {|x| reserved?(x)}
      end
      candidates
    end

    def to_candidate_array(object, array)
      array.map do |candidate|
        case candidate
        when String
          [->{candidate}]
        when Array
          to_candidate_array(object, candidate).flatten
        when Symbol
          [object.method(candidate)]
        else
          if candidate.respond_to?(:call)
            [candidate]
          else
            [->{candidate.to_s}]
          end
        end
      end
    end

    def wanted?(slug)
      slug.present?
    end

    def reserved?(slug)
      config = @object.friendly_id_config
      return false unless config.uses? ::FriendlyId::Reserved
      return false unless config.reserved_words
      config.reserved_words.include?(slug)
    end
  end
end
