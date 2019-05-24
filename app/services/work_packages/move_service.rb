# Moves/copies an work_package to a new project and type

class WorkPackages::MoveService
  attr_accessor :work_package,
                :user

  def initialize(work_package, user)
    self.work_package = work_package
    self.user = user
  end

  def call(new_project, new_type = nil, options = {})
    attributes = options[:attributes] || {}
    attributes[:project] = new_project
    attributes[:type] = new_type if new_type
    attributes[:journal_notes] = options[:journal_note] if options[:journal_note]

    if options[:copy]
      copy_with_descendants(attributes)
    else
      update(attributes)
    end
  end

  def copy_with_descendants(attributes)
    ancestors = {}
    result = copy_with_updated_parent_id(work_package, attributes, ancestors)

    work_package
      .descendants
      .order_by_ancestors('asc')
      .each do |wp|

      copied = copy_with_updated_parent_id(wp, attributes, ancestors)

      result.add_dependent!(copied)
    end

    result
  end

  def copy(wp, attributes)
    WorkPackages::CopyService
      .new(user: user,
           work_package: wp)
      .call(attributes.symbolize_keys)
  end

  def update(attributes)
    WorkPackages::UpdateService
      .new(user: user,
           model: work_package)
      .call(attributes.symbolize_keys)
  end

  def copy_with_updated_parent_id(wp, attributes, ancestors)
    with_updated_parent_id(wp, attributes, ancestors) do |overridden_attributes|
      copy(wp, overridden_attributes)
    end
  end

  def with_updated_parent_id(work_package, attributes, ancestors)
    # avoid modifying attributes which could carry over
    # to the next work_package
    overridden_attributes = attributes.dup

    overridden_attributes[:parent_id] = ancestors[work_package.parent_id] || work_package.parent_id if work_package.parent_id

    copied = yield overridden_attributes

    ancestors[work_package.id] = copied.result.id

    copied
  end
end
