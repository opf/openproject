(function ($) {
    $(function() {
        window.homescreenOnboardingTourSteps = [
            {
                'next #top-menu': I18n.t('js.onboarding.steps.welcome'),
                'skipButton': {className: 'enjoyhint_btn-transparent'},
                'containerClass': '-hidden-arrow'
            },
            {
                'description': I18n.t('js.onboarding.steps.project_selection'),
                'selector': '.widget-box.welcome',
                'event': 'custom',
                'showSkip': false,
                'containerClass': '-dark -hidden-arrow',
                'containerClass': '-dark -hidden-arrow',
                'clickable': true,
                onBeforeStart: function () {
                    $(".widget-box.welcome a").click(function (e) {
                        e.preventDefault();
                        e.stopPropagation();
                    });

                    // Handle the correct project selection and redirection
                    // This will be removed once the project selection is implemented
                    $(".widget-box.welcome a:contains(scrumDemoProjectName)").click(function () {
                        tutorialInstance.trigger('next');
                        window.location = this.href + '/backlogs';
                    });
                    $(".widget-box.welcome a:contains(demoProjectName)").click(function () {
                        tutorialInstance.trigger('next');
                        window.location = this.href + '/work_packages';
                    });
                    // Disable clicks on the wp context menu links
                    $('.widget-box--blocks--buttons .button').addClass('-disabled').bind('click', preventClickHandler);
                }
            }
        ];
    });
}(jQuery))
