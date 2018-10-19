(function ($) {
    $(function() {
        window.overviewOnboardingTourSteps = [
            {
                'next #content-wrapper': I18n.t('js.onboarding.steps.project_overview'),
                'showSkip': false,
                'containerClass': '-dark -hidden-arrow'
            },
            {
                'next #menu-sidebar': I18n.t('js.onboarding.steps.sidebar'),
                'showSkip': false
            },
            {
                'next .settings-menu-item': I18n.t('js.onboarding.steps.settings'),
                'showSkip': false
            },
            {
                'next .members-menu-item': I18n.t('js.onboarding.steps.members'),
                'showSkip': false
            },
            {
                'custom .toggler': I18n.t('js.onboarding.steps.wp_toggler'),
                'showSkip': false,
                'shape': 'circle',
                'radius': 20,
                'clickable': true,
                onBeforeStart: function () {
                    waitForElement('.wp-query-menu--item', '.wp-query-menu--results-container', function() {
                        tutorialInstance.trigger('next');
                    });
                }
            },
            {
                "click .wp-query-menu--item[data-category='default']": I18n.t('js.onboarding.steps.wp_query'),
                'showSkip': false,
                'margin': 0,
                'clickable': true
            }
        ];

        window.scrumOverviewOnboardingTourSteps = [
            {
                'next #content-wrapper': I18n.t('js.onboarding.steps.project_overview'),
                'showSkip': false,
                'containerClass': '-dark'
            },
            {
                'next #menu-sidebar': I18n.t('js.onboarding.steps.sidebar'),
                'showSkip': false
            },
            {
                'next .settings-menu-item': I18n.t('js.onboarding.steps.settings'),
                'showSkip': false
            },
            {
                'next .members-menu-item': I18n.t('js.onboarding.steps.members'),
                'showSkip': false
            },
            {
                'click .backlogs-menu-item': I18n.t('js.onboarding.steps.backlogs'),
                'showSkip': false,
                'margin': 0,
                'clickable': true
            }
        ];
    });
}(jQuery))
