require_dependency 'journal_formatter'

# The ActiveRecord model representing journals.
class Journal < ActiveRecord::Base
  unloadable

  include Comparable
  include JournalFormatter
  include JournalDeprecated

  # Make sure each journaled model instance only has unique version ids
  validates_uniqueness_of :version, :scope => [:journaled_id, :type]
  belongs_to :journaled
  belongs_to :user

  # ActiveRecord::Base#changes is an existing method, so before serializing the +changes+ column,
  # the existing +changes+ method is undefined. The overridden +changes+ method pertained to
  # dirty attributes, but will not affect the partial updates functionality as that's based on
  # an underlying +changed_attributes+ method, not +changes+ itself.
  # undef_method :changes
  serialize :changes, Hash

  # In conjunction with the included Comparable module, allows comparison of journal records
  # based on their corresponding version numbers, creation timestamps and IDs.
  def <=>(other)
    [version, created_at, id].map(&:to_i) <=> [other.version, other.created_at, other.id].map(&:to_i)
  end

  # Returns whether the version has a version number of 1. Useful when deciding whether to ignore
  # the version during reversion, as initial versions have no serialized changes attached. Helps
  # maintain backwards compatibility.
  def initial?
    version < 2
  end

  # The anchor number for html output
  def anchor
    version - 1
  end

  # Possible shortcut to the associated project
  def project
    if journaled.respond_to?(:project)
      journaled.project
    elsif journaled.is_a? Project
      journaled
    else
      nil
    end
  end

  def editable_by?(user)
    journaled.journal_editable_by?(user)
  end

  def details
    attributes["changes"] || {}
  end

  alias_method :changes, :details

  def new_value_for(prop)
    details[prop.to_s].last if details.keys.include? prop.to_s
  end

  def old_value_for(prop)
    details[prop.to_s].first if details.keys.include? prop.to_s
  end
  
  # Returns a string of css classes
  def css_classes
    s = 'journal'
    s << ' has-notes' unless notes.blank?
    s << ' has-details' unless details.empty?
    s
  end

  # This is here to allow people to disregard the difference between working with a
  # Journal and the object it is attached to.
  # The lookup is as follows:
  ## => Call super if the method corresponds to one of our attributes (will end up in AR::Base)
  ## => Try the journaled object with the same method and arguments
  ## => On error, call super
  def method_missing(method, *args, &block)
    return super if attributes[method.to_s]
    journaled.send(method, *args, &block)
  rescue NoMethodError => e
    e.name == method ? super : raise(e)
  end

end
