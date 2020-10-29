module FriendlyId
  # The default slug generator offers functionality to check slug candidates for
  # availability.
  class SlugGenerator

    def initialize(scope, config)
      @scope = scope
      @config = config
    end

    def available?(slug)
      if @config.uses?(::FriendlyId::Reserved) && @config.reserved_words.present? && @config.treat_reserved_as_conflict
        return false if @config.reserved_words.include?(slug)
      end

      !@scope.exists_by_friendly_id?(slug)
    end

    def generate(candidates)
      candidates.each {|c| return c if available?(c)}
      nil
    end

  end
end
