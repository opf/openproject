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

class JournalFormatter::NamedAssociation < JournalFormatter::Attribute
  # unloadable

  def render(key, values, options = { :no_html => false })

    label, old_value, value = format_details(key, values, options)

    unless options[:no_html]
      label, old_value, value = *format_html_details(label, old_value, value)
    end

    render_ternary_detail_text(label, value, old_value)
  end

  private

  def format_details(key, values, options = {})
    label = label(key)

    old_value, value = *format_values(values, key, options)

    [label, old_value, value]
  end

  def format_values(values, key, options)
    field = key.to_s.gsub(/\_id$/, "").to_sym
    klass = class_from_field(field)

    values.map do |value|
      if klass
        record = associated_object(klass, value.to_i, options)
        if record
          if record.respond_to? 'name'
            record.name
          else
            record.subject
          end
        end
      end
    end
  end

  def associated_object(klass, id, options = {})
    cache = options[:cache]

    if cache && cache.is_a?(Acts::Journalized::JournalObjectCache)
      cache.fetch(klass, id) do |k, i|
        k.find_by_id(i)
      end
    else
      klass.find_by_id(id)
    end
  end

  def class_from_field(field)
    association = @journal.journable.class.reflect_on_association(field)

    if association
      association.class_name.constantize
    end
  end
end
