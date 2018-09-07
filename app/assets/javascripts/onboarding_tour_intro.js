//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See docs/COPYRIGHT.rdoc for more details.
//++


jQuery(document).ready(function($) {
    var intro = introJs();
    intro.setOptions({
        steps: [
            {
                intro: "Welcome to our short introduction tour to show you the important features in OpenProject. We recommend to complete the steps till the end."
            },
            {
                element: ".overview-menu-item",
                intro: "This is the project’s Overview page. A dashboard with important information. You can customize it with X"
            },
            {
                element: "#menu-sidebar",
                intro: "From the project menu you can access all modules within a project or collapse it with X. In the Project settings you can configure your project’s modules."
            },
            {
                element: ".members-menu-item",
                intro: "Invite new Members to join your project."
            }
        ],
        doneLabel: 'Next page'
    });
    intro.oncomplete(function() {
        window.location = window.location + '/work_packages?multipage=true';
    });

    $('#onboarding_tour_introjs').click(function () {
        startIntroJsTutorial();
    });

    if (RegExp('multipage', 'gi').test(window.location.search)) {
        introJs().setOptions({steps: [
            {
                intro: "Create and manage your Work packages within a project."
            }]}).start();
    }

    function startIntroJsTutorial() {
        intro.start();
    }
});
