#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
# See COPYRIGHT and LICENSE files for more details.
#++

FactoryBot.define do
  factory :webdav_data, class: "String" do
    transient do
      origin_user_id { "admin" }
      root_path { "" }
      parent_path { "" }
    end

    skip_create

    initialize_with do
      url_safe_user_id = origin_user_id.gsub(" ", "%20")
      base_path = File.join(root_path, "/remote.php/dav/files", url_safe_user_id, parent_path)

      Nokogiri::XML::Builder.new do |xml|
        xml["d"].multistatus(
          "xmlns:d" => "DAV:",
          "xmlns:s" => "http://sabredav.org/ns",
          "xmlns:oc" => "http://owncloud.org/ns",
          "xmlns:nc" => "http://nextcloud.org/ns"
        ) do
          xml["d"].response do
            xml["d"].href(base_path)
            xml["d"].propstat do
              xml["d"].prop do
                xml["oc"].fileid("6")
                xml["oc"].size("20028269")
                xml["d"].getlastmodified("Fri, 28 Oct 2022 14:27:36 GMT")
                xml["oc"].permissions("RGDNVCK")
                xml["oc"].send(:"owner-display-name", url_safe_user_id)
              end
              xml["d"].status("HTTP/1.1 200 OK")
            end
            xml["d"].propstat do
              xml["d"].prop do
                xml["d"].getcontenttype
              end
              xml["d"].status("HTTP/1.1 404 Not Found")
            end
          end
          xml["d"].response do
            xml["d"].href(File.join(base_path, "Folder1", ""))
            xml["d"].propstat do
              xml["d"].prop do
                xml["oc"].fileid("11")
                xml["oc"].size("6592")
                xml["d"].getlastmodified("Fri, 28 Oct 2022 14:31:26 GMT")
                xml["oc"].permissions("RGDNVCK")
                xml["oc"].send(:"owner-display-name", url_safe_user_id)
              end
              xml["d"].status("HTTP/1.1 200 OK")
            end
            xml["d"].propstat do
              xml["d"].prop do
                xml["d"].getcontenttype
              end
              xml["d"].status("HTTP/1.1 404 Not Found")
            end
          end
          xml["d"].response do
            xml["d"].href(File.join(base_path, "Folder2", ""))
            xml["d"].propstat do
              xml["d"].prop do
                xml["oc"].fileid("20")
                xml["oc"].size("8592")
                xml["d"].getlastmodified("Fri, 28 Oct 2022 14:43:26 GMT")
                xml["oc"].permissions("RGDNV")
                xml["oc"].send(:"owner-display-name", url_safe_user_id)
              end
              xml["d"].status("HTTP/1.1 200 OK")
            end
            xml["d"].propstat do
              xml["d"].prop do
                xml["d"].getcontenttype
              end
              xml["d"].status("HTTP/1.1 404 Not Found")
            end
          end
          xml["d"].response do
            xml["d"].href(File.join(base_path, "README.md"))
            xml["d"].propstat do
              xml["d"].prop do
                xml["oc"].fileid("12")
                xml["oc"].size("1024")
                xml["d"].getcontenttype("text/markdown")
                xml["d"].getlastmodified("Thu, 14 Jul 2022 08:42:15 GMT")
                xml["oc"].permissions("RGDNVW")
                xml["oc"].send(:"owner-display-name", url_safe_user_id)
              end
              xml["d"].status("HTTP/1.1 200 OK")
            end
          end
          xml["d"].response do
            xml["d"].href(File.join(base_path, "Manual.pdf"))
            xml["d"].propstat do
              xml["d"].prop do
                xml["oc"].fileid("13")
                xml["oc"].size("12706214")
                xml["d"].getcontenttype("application/pdf")
                xml["d"].getlastmodified("Thu, 14 Jul 2022 08:42:15 GMT")
                xml["oc"].permissions("RGDNV")
                xml["oc"].send(:"owner-display-name", url_safe_user_id)
              end
              xml["d"].status("HTTP/1.1 200 OK")
            end
          end
        end
      end.to_xml
    end
  end

  factory :webdav_data_folder, class: "String" do
    skip_create

    initialize_with do
      Nokogiri::XML::Builder.new do |xml|
        xml["d"].multistatus(
          "xmlns:d" => "DAV:",
          "xmlns:s" => "http://sabredav.org/ns",
          "xmlns:oc" => "http://owncloud.org/ns",
          "xmlns:nc" => "http://nextcloud.org/ns"
        ) do
          xml["d"].response do
            xml["d"].href("/remote.php/dav/files/admin/Folder1")
            xml["d"].propstat do
              xml["d"].prop do
                xml["oc"].fileid("11")
                xml["oc"].size("6592")
                xml["d"].getlastmodified("Fri, 28 Oct 2022 14:31:26 GMT")
                xml["oc"].permissions("RGDNVCK")
                xml["oc"].send(:"owner-display-name", "admin")
              end
              xml["d"].status("HTTP/1.1 200 OK")
            end
            xml["d"].propstat do
              xml["d"].prop do
                xml["d"].getcontenttype
              end
              xml["d"].status("HTTP/1.1 404 Not Found")
            end
          end
          xml["d"].response do
            xml["d"].href("/remote.php/dav/files/admin/Folder1/logo.png")
            xml["d"].propstat do
              xml["d"].prop do
                xml["oc"].fileid("21")
                xml["oc"].size("2048")
                xml["d"].getcontenttype("image/png")
                xml["d"].getlastmodified("Fri, 28 Oct 2022 14:31:26 GMT")
                xml["oc"].permissions("RGDNVW")
                xml["oc"].send(:"owner-display-name", "admin")
              end
              xml["d"].status("HTTP/1.1 200 OK")
            end
          end
          xml["d"].response do
            xml["d"].href("/remote.php/dav/files/admin/Folder1/jingle.ogg")
            xml["d"].propstat do
              xml["d"].prop do
                xml["oc"].fileid("22")
                xml["oc"].size("22736218")
                xml["d"].getcontenttype("audio/ogg")
                xml["d"].getlastmodified("Fri, 28 Oct 2022 14:31:26 GMT")
                xml["oc"].permissions("RGDNVW")
                xml["oc"].send(:"owner-display-name", "admin")
              end
              xml["d"].status("HTTP/1.1 200 OK")
            end
          end
          xml["d"].response do
            xml["d"].href("/remote.php/dav/files/admin/Folder1/notes.txt")
            xml["d"].propstat do
              xml["d"].prop do
                xml["oc"].fileid("23")
                xml["oc"].size("128")
                xml["d"].getcontenttype("text/plain")
                xml["d"].getlastmodified("Fri, 28 Oct 2022 14:31:26 GMT")
                xml["oc"].permissions("RGDNVW")
                xml["oc"].send(:"owner-display-name", "admin")
              end
              xml["d"].status("HTTP/1.1 200 OK")
            end
          end
        end
      end.to_xml
    end
  end
end
