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
                    // Handle the correct project selection and redirection
                    // This will be removed once the project selection is implemented
                    jQuery(".widget-box.welcome a:contains(" + scrumDemoProjectName + ")").click(function () {
                        tutorialInstance.trigger('next');
                        window.location = this.href + '/backlogs';
                    });
                    jQuery(".widget-box.welcome a:contains(" + demoProjectName + ")").click(function () {
                        tutorialInstance.trigger('next');
                        window.location = this.href + '/work_packages';
                    });
                    // Disable clicks on other links
                    $('.widget-box.welcome a').addClass('-disabled').bind('click', preventClickHandler);
                }
            }
        ];
    });
}(jQuery))
