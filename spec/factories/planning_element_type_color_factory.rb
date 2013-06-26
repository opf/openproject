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

FactoryGirl.define do
  factory(:color, :class => PlanningElementTypeColor) do
    sequence(:name) { |n| "Color No. #{n}" }
    hexcode { ("#%0.6x" % rand(0xFFFFFF)).upcase }
    sequence(:position) { |n| n }
  end
end

{'maroon'  => '#800000',
 'red'     => '#FF0000',
 'orange'  => '#FFA500',
 'yellow'  => '#FFFF00',
 'olive'   => '#808000',
 'purple'  => '#800080',
 'fuchsia' => '#FF00FF',
 'white'   => '#FFFFFF',
 'lime'    => '#00FF00',
 'green'   => '#008000',
 'navy'    => '#000080',
 'blue'    => '#0000FF',
 'aqua'    => '#00FFFF',
 'teal'    => '#008080',
 'black'   => '#000000',
 'silver'  => '#C0C0C0',
 'gray'    => '#808080'}.each do |name, code|

  FactoryGirl.define do
    factory(:"color_#{name}", :parent => :color) do
      name    name
      hexcode code
    end
  end
end
