module Engine
  ##
  # Subclass of Report to be used for constant lookup and such.
  # It is considered public API to override this method i.e. in Tests.
  #
  # @return [Class] subclass
  def engine
    return @engine if @engine
    if is_a? Module
      @engine = Object.const_get(name[/^[^:]+/] || :Report)
    elsif respond_to? :parent and parent.respond_to? :engine
      parent.engine
    else
      self.class.engine
    end
  end
end