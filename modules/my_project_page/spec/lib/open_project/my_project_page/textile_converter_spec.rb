#-- copyright
# OpenProject My Project Page Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

require 'spec_helper'

describe ::OpenProject::TextFormatting::Formats::Markdown::TextileConverter, type: :model do
  let(:left) do
    [["s",
      "OpenProject Community",
      "!openproject-community.jpg!\r\nThis is the community project where the development of the OpenProject software and plugins takes place.\r\n\r\nOpenProject is free and open source web-based project collaboration software. It supports your project teams throughout the whole project life cycle. The software is developed by an active international community, governed by the OpenProject Foundation.\r\n\r\n\r\nBe part of the OpenProject community - with open source and open mind."],
     ["c",
      "Open Source for Enterprise",
      "!collaboration.jpg!\r\nUsing open source software for corporate organisations? – For sure!\r\n\r\nOpenProject offers powerful collaboration features and meets highest requirements in data privacy and security. It offers an appealing and intuitive user interface. Also, the majority of features is fully accessible.\r\nDue to continuous development and enhancements, OpenProject has an enormous potential, which outdrives common project management software. \r\n\r\nOpen your mind – participate!\r\n\r\n\"find out more ›\":https://www.openproject.com/enterprise-edition/"],
     ["x",
      "OpenProject Cloud Edition",
      "*Want to use OpenProject for your own organization?*\r\n\r\n!Cloud.png!\r\nOpenProject offers a variety of features to support your teams throughout the whole project life-cycle. Rely on the experts to take care of your OpenProject installation.\r\n\r\nYou do not need to bother about installing and maintaining your OpenProject installation, nor about security fixes and feature updates since you will always receive the latest OpenProject release automatically. Your OpenProject instance will be hosted on reliable and secure servers with high availability and redundancy.\r\n\r\n\"find out more ›\":https://www.openproject.com/hosting\r\n"]]
  end
  let(:right) do
    [["m",
      "About OpenProject",
      "!new_openproject_website.jpg!\r\nOpenProject is open source project collaboration software. It supports project teams throughout the whole project management life-cycle.\r\nYou can get more information about the following topics:\r\n\r\n*Feature Tour*\r\n!feature_icons.jpg!\r\nLearn more about OpenProject features and published plugins.\r\n\"go to features ›\":https://www.openproject.com/collaboration-software-features/\r\n\r\n*OpenProject Professional Services*\r\nWould you like to use OpenProject in the cloud or book professional enterprise services.\r\n\"find out more ›\":https://www.openproject.org/\r\n\r\n*Download and installation*\r\nHere you can find information about how to download and install your own OpenProject instance, either manually or by packager.\r\n\"find out more ›\":https://www.openproject.org/download-and-installation/\r\n\r\n*Develop OpenProject*\r\nThis is the place to find all the information around code, development and workflow of OpenProject.\r\n\"find out more ›\":https://www.openproject.org/develop-openproject/\r\n\r\n*Blog*\r\nOur OpenProject News moved to a new Blog.\r\n\"read the articles ›\":https://www.openproject.org/blog/\r\n\r\n*Help*\r\nYou will find support on our new \"Help\":https://www.openproject.org/help/ page (including user guides).\r\n\"go to Forums ›\":https://community.openproject.com/projects/openproject/boards\r\n\"go to Shortcuts ›\":https://www.openproject.org/help/keyboard-shortcuts-access-keys/\r\n\"go to Glossary ›\":https://www.openproject.org/help/glossary/\r\n\r\n*Cannot find an answer? - Contact us.*\r\nIf you have questions or comments and cannot find your answer right away, write us an e-mail: info@openproject.org.\r\n"],
     ["j", "Follow us", "!followus_twitter.jpg!:https://twitter.com/openproject     !followus_GitHub.jpg!:https://github.com/opf/openproject"]]
  end
  let(:top) do
    [["r", "", "!openproject-small.png!\r\n"], ["u", "Development timeline", "{{timeline(36)}}"]]
  end
  let(:hidden) do
    ["work_package_tracking",
     "project_details",
     ["o",
      "OpenProject Survey",
      "h3. \"OpenProject Survey 2014 Q2\":https://www.openproject.org/survey_pages/11\r\n\r\nDear OpenProject users,\r\n\r\nWe are passionate about OpenProject and are keen to improve it so it better suits your needs. Therefore, we would like to find out what you are looking for, how you use the software and what you think about it.\r\n\r\nPlease take only 5 minutes to answer our questions in the following survey. Be sure that we will treat everything confidential. With your answers, we aim to make OpenProject even better!\r\n\r\nThanks!\r\nYour OpenProject team\r\n\r\n\"go to OpenProject \":https://www.openproject.org/survey_pages/11"]]
  end
  let(:blocks) do
    FactoryBot.create(:my_projects_overview, left: left, right: right, top: top, hidden: hidden)
  end

  it 'transforms all blocks' do
    blocks

    described_class.new.run!

    blocks.reload

    expect(blocks.left)
      .not_to eql(left)

    expect(blocks.right)
      .not_to eql(right)

    expect(blocks.top)
      .not_to eql(top)

    expect(blocks.hidden)
      .not_to eql(hidden)
  end
end
