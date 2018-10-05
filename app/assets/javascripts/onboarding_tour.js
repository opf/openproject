(function ($) {
    $(function() {
        var tutorial_instance;
        var onboardng_tour_steps_1 = [
            {
                'next #logo' : 'Welcome to our short introduction tour to show you the important features in OpenProject. We recommend to complete the steps till the end.',
                'showSkip' : false
            },
            {
                'next #content' : 'This is the project’s Overview page. A dashboard with important information. You can customize it with the settings icon on the right.',
                'showSkip' : false,
                'labelClass' : '-dark'
            },
            {
                'next #menu-sidebar' : 'From the project menu you can access all modules within a project or collapse it with the icon on the top.',
                'showSkip' : false
            },
            {
                'next .settings-menu-item' : 'In the Project settings you can configure your project’s modules.',
                'showSkip' : false
            },
            {
                'next .members-menu-item' : 'Invite new Members to join your project.',
                'showSkip' : false
            },
            {
                'click .toggler' : 'Here is the Work package section. Have a look and click on the arrow.',
                'showSkip' : false,
                'shape' : 'circle'
            },
            {
                'click .wp-query-menu--item-link': "Let's have a look at currently opened work packages. Click on the link to see them.",
                'showSkip' : false,
                'timeout' : 200
            }
        ];

        var onboardng_tour_steps_2 = [
            {
                'click .wp-table--row' : 'Double click on a work package row or click the info icon to open the details.',
                'showSkip' : false,
                'timeout' : 800
            },
            {
                'next .work-packages--details' : 'Within the work package details you find all relevant information, such as description, status and priority, activities or comments.',
                'showSkip' : false,
                'labelClass' : '-dark'
            },
            {
                'next .add-work-package' : 'The Create button will add a new work package to your project.',
                'showSkip' : false,
                'shape' : 'circle'
            },
            {
                'click .timeline-toolbar--button' : 'On the top, you can also activate the Gantt chart. Try it out!',
                'showSkip' : false,
                'shape' : 'circle'
            },
            {
                'next .work-packages-tabletimeline--timeline-side' : 'Here you can create and visualize a project plan and share it with your team.',
                'showSkip' : false,
                'labelClass' : '-dark'
            },
            {
                'next .menu-item--help' : 'In the Help menu you will find a user guide and additional help resources. Enjoy your work with OpenProject!',
                'shape' : 'circle',
                "nextButton" : {className: "myNext", text: "Got it"},
                'showSkip' : false
            }
        ];


        $('#onboarding_tour_enjoyhint').click(function () {
            tutorial_instance = new EnjoyHint();
            tutorial_instance.set(onboardng_tour_steps_1);
            startOnboardingTutorial();
        });

        if (top.location.pathname === '/projects/project-with-no-members/work_packages')
        {
            tutorial_instance = new EnjoyHint();
            tutorial_instance.set(onboardng_tour_steps_2);
            startOnboardingTutorial();
        }

        function startOnboardingTutorial() {
            tutorial_instance.run();
        }
    });
}(jQuery));
