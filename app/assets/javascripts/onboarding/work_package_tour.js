(function ($) {
    $(function() {
        window.wpOnboardingTourSteps = [
            {
                'custom .wp-table--row': I18n.t('js.onboarding.steps.wp_list'),
                'showSkip': false,
                'margin': 5,
                'clickable': true,
                onBeforeStart: function () {
                    // Handle next step
                    $('.wp-table--row ').dblclick(function (e) {
                        if (!$(e.target).hasClass('wp-edit-field--display-field')) tutorialInstance.trigger('next');
                    });

                    // Disable clicks on the wp context menu links
                    $('.wp-table--details-link, .wp-table-context-menu-link, .wp-table--cell-span').addClass('-disabled').bind('click', preventClickHandler);
                }
            },
            {
                'next .work-packages-full-view--split-left': I18n.t('js.onboarding.steps.wp_full_view'),
                'showSkip': false,
                'containerClass': '-dark'
            },
            {
                'click .work-packages-list-view-button': I18n.t('js.onboarding.steps.wp_back_button'),
                'showSkip': false,
                'clickable': true
            },
            {
                'next .add-work-package': I18n.t('js.onboarding.steps.wp_create_button'),
                'showSkip': false,
                'shape': 'circle'
            },
            {
                'click .timeline-toolbar--button': I18n.t('js.onboarding.steps.wp_timeline_button'),
                'showSkip': false,
                'shape': 'circle',
                'clickable': true
            },
            {
                'next .work-packages-tabletimeline--timeline-side': I18n.t('js.onboarding.steps.wp_timeline'),
                'showSkip': false,
                'containerClass': '-dark'
            },
            {
                'next .menu-item--help': I18n.t('js.onboarding.steps.help_menu'),
                'shape': 'circle',
                'nextButton': {text: I18n.t('js.onboarding.steps.got_it')},
                'showSkip': false
            }
        ];
    });
}(jQuery))
