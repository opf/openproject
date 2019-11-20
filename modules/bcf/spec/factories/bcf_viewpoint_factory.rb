#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013-2014 the OpenProject Foundation (OPF)
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

FactoryBot.define do
  factory :bcf_viewpoint, class: ::Bcf::Viewpoint do
    new_uuid = SecureRandom.uuid
    uuid { new_uuid }
    viewpoint_name { "Viewpoint_#{new_uuid}.bcfv" }
    viewpoint do
      <<~MARKUP
        <?xml version="1.0" encoding="utf-8"?>
        <!--Created with the iabi.BCF library, V1.1.0 at 22.05.2017 09:51. Visit http://iabi.eu to find out more.-->
        <VisualizationInfo xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" Guid="8dc86298-9737-40b4-a448-98a9e953293a">
          <Components>
            <ViewSetupHints SpacesVisible="true" SpaceBoundariesVisible="true" OpeningsVisible="true" />
            <Selection>
              <Component IfcGuid="0cSRUx$EX1NRjqiKcYQ$a0" />
              <Component IfcGuid="1jQQiGIAnFzxOUzrdmJYDS" />
              <Component IfcGuid="0fdpeZZEX3FwJ7x0ox5kzF" />
              <Component IfcGuid="23Zwlpd71EyvHlH6OZ77nK" />
              <Component IfcGuid="1OpjQ1Nlv4sQuTxfUC_8zS" />
            </Selection>
            <Visibility DefaultVisibility="true">
              <Exceptions>
                <Component IfcGuid="0Gl71cVurFn8bxAOox6M4X" />
                <Component IfcGuid="23Zwlpd71EyvHlH6OZ77nK" />
                <Component IfcGuid="3DvyPxGIn8qR0KDwbL_9r1" />
                <Component IfcGuid="0fdpeZZEX3FwJ7x0ox5kzF" />
                <Component IfcGuid="1OpjQ1Nlv4sQuTxfUC_8zS" />
              </Exceptions>
            </Visibility>
            <Coloring>
              <Color Color="3498db">
                <Component IfcGuid="0fdpeZZEX3FwJ7x0ox5kzF" />
                <Component IfcGuid="23Zwlpd71EyvHlH6OZ77nK" />
                <Component IfcGuid="1OpjQ1Nlv4sQuTxfUC_8zS" />
                <Component IfcGuid="0cSRUx$EX1NRjqiKcYQ$a0" />
              </Color>
            </Coloring>
          </Components>
          <PerspectiveCamera>
            <CameraViewPoint>
              <X>12.2088897788292</X>
              <Y>52.323145074034</Y>
              <Z>5.24072091171001</Z>
            </CameraViewPoint>
            <CameraDirection>
              <X>-0.381615611200324</X>
              <Y>-0.825232810204882</Y>
              <Z>-0.416365617893758</Z>
            </CameraDirection>
            <CameraUpVector>
              <X>0.05857014928797</X>
              <Y>0.126656300502579</Y>
              <Z>0.990215996212637</Z>
            </CameraUpVector>
            <FieldOfView>60</FieldOfView>
          </PerspectiveCamera>
          <Lines>
            <Line>
              <StartPoint>
                <X>0</X>
                <Y>0</Y>
                <Z>0</Z>
              </StartPoint>
              <EndPoint>
                <X>0</X>
                <Y>0</Y>
                <Z>1</Z>
              </EndPoint>
            </Line>
            <Line>
              <StartPoint>
                <X>0</X>
                <Y>0</Y>
                <Z>1</Z>
              </StartPoint>
              <EndPoint>
                <X>0</X>
                <Y>1</Y>
                <Z>1</Z>
              </EndPoint>
            </Line>
            <Line>
              <StartPoint>
                <X>0</X>
                <Y>1</Y>
                <Z>1</Z>
              </StartPoint>
              <EndPoint>
                <X>1</X>
                <Y>1</Y>
                <Z>1</Z>
              </EndPoint>
            </Line>
          </Lines>
          <ClippingPlanes>
            <ClippingPlane>
              <Location>
                <X>0</X>
                <Y>0</Y>
                <Z>0</Z>
              </Location>
              <Direction>
                <X>0</X>
                <Y>0</Y>
                <Z>1</Z>
              </Direction>
            </ClippingPlane>
            <ClippingPlane>
              <Location>
                <X>0</X>
                <Y>0</Y>
                <Z>0</Z>
              </Location>
              <Direction>
                <X>0</X>
                <Y>1</Y>
                <Z>0</Z>
              </Direction>
            </ClippingPlane>
          </ClippingPlanes>
        </VisualizationInfo>
      MARKUP
    end

    transient do
      snapshot { nil }
    end

    after(:create) do |viewpoint, evaluator|
      unless evaluator.snapshot == false
        create(:bcf_viewpoint_attachment, container: viewpoint)
      end
    end
  end
end
