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
                'next .toggler': I18n.t('js.onboarding.steps.wp_toggler'),
                'showSkip': false,
                'shape': 'circle',
                onNext: function () {
                    $('#main-menu-work-packages-wrapper .toggler').click();
                }
            },
            {
                "next .wp-query-menu--item[data-category='default']": I18n.t('js.onboarding.steps.wp_query'),
                'showSkip': false,
                onNext: function () {
                    $(".wp-query-menu--item[data-category='default'] .wp-query-menu--item-link")[0].click();
                }
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
                'next .backlogs-menu-item': I18n.t('js.onboarding.steps.backlogs'),
                'showSkip': false,
                onNext: function () {
                    $('.backlogs-menu-item')[0].click();
                }
            }
        ];
    });
}(jQuery))
