module Disposable::Twin::Changed
  class Changes < Hash
    def changed?(name=nil)
      return true if name.nil? and values.find { |val| val == true } # TODO: this could be speed-improved, of course.

      !! self[name.to_s]
    end
  end


  def changed?(*args) # not recommended for external use?
    changed.changed?(*args)
  end

# FIXME: can we make #changed the only public concept? so we don't need to find twice?

  # this is usually called only once in Sync::SkipUnchanged, per twin.
  def changed
    _find_changed_twins!(@_changes)

    @_changes
  end

private
  def initialize(model, *args)
    super         # Setup#initialize.
    @_changes = Changes.new # override changed from initialize.
  end

  def _changed
    @_changes ||= Changes.new # FIXME: why do we need to re-initialize here?
  end

  def write_property(name, value, dfn)
    old_value = field_read(name)

    super.tap do
      _changed[name.to_s] = old_value != value
    end
  end

  def _find_changed_twins!(changes) # FIXME: this will change soon. don't touch.
    schema.each(twin: true) do |dfn|
      next unless twin = send(dfn.getter)
      next unless twin.changed?

      changes[dfn[:name]] = true
    end
  end
end