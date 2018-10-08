(function ($) {
    $(function() {
        var preventClickHandler = function(e) {
            e.preventDefault();
            e.stopPropagation();
        };
        var localStorageKey = 'openProject-onboardingTour';

        var OverviewOnboardingTourSteps = [
            {
                'next #logo' : I18n.t('js.onboarding.steps.welcome'),
                'showSkip' : false
            },
            {
                'next #content' : I18n.t('js.onboarding.steps.project_overview'),
                'showSkip' : false,
                'containerClass' : '-dark'
            },
            {
                'next #menu-sidebar' : I18n.t('js.onboarding.steps.sidebar'),
                'showSkip' : false
            },
            {
                'next .settings-menu-item' : I18n.t('js.onboarding.steps.settings'),
                'showSkip' : false
            },
            {
                'next .members-menu-item' : I18n.t('js.onboarding.steps.members'),
                'showSkip' : false
            },
            {
                'click .toggler' : I18n.t('js.onboarding.steps.wp_toggler'),
                'showSkip' : false,
                'shape' : 'circle',
                'radius' : 20,
                onBeforeStart: function () {
                    $('.enjoyhint').toggleClass('-clickable', true);
                }
            },
            {
                "click .wp-query-menu--item[data-category='default']": I18n.t('js.onboarding.steps.wp_query'),
                'showSkip' : false,
                'timeout' : 200,
                'margin' : 0,
                onBeforeStart: function () {
                    $('.enjoyhint').toggleClass('-clickable', true);
                }
            }
        ];

        var WpOnboardingTourSteps = [
            {
                'custom .wp-table--row' : I18n.t('js.onboarding.steps.wp_list'),
                'showSkip' : false,
                'margin' : 5,
                onBeforeStart: function(){
                    $('.enjoyhint').toggleClass('-clickable', true);
                    // Handle next step
                    $('.wp-table--row').dblclick(function() {
                        tutorialInstance.trigger('next');
                    });
                    $('.wp-table--cell-td.id a').click(function() {
                        tutorialInstance.trigger('next');
                    });

                    // Disable clicks on the wp context menu links
                    $('.wp-table--details-link, .wp-table-context-menu-link').addClass('-disabled').bind('click', preventClickHandler);
                }
            },
            {
                'next .work-packages-full-view--split-left' : I18n.t('js.onboarding.steps.wp_full_view'),
                'showSkip' : false,
                'containerClass' : '-dark'
            },
            {
                'click .work-packages-list-view-button' : I18n.t('js.onboarding.steps.wp_back_button'),
                'showSkip' : false,
                onBeforeStart: function () {
                    $('.enjoyhint').toggleClass('-clickable', true);
                }
            },
            {
                'next .add-work-package' : I18n.t('js.onboarding.steps.wp_create_button'),
                'showSkip' : false,
                'shape' : 'circle'
            },
            {
                'click .timeline-toolbar--button' : I18n.t('js.onboarding.steps.wp_timeline_button'),
                'showSkip' : false,
                'shape' : 'circle',
                onBeforeStart: function () {
                    $('.enjoyhint').toggleClass('-clickable', true);
                }
            },
            {
                'next .work-packages-tabletimeline--timeline-side' : I18n.t('js.onboarding.steps.wp_timeline'),
                'showSkip' : false,
                'containerClass' : '-dark'
            },
            {
                'next .menu-item--help' : I18n.t('js.onboarding.steps.help_menu'),
                'shape' : 'circle',
                "nextButton" : {text: "Got it"},
                'showSkip' : false
            }
        ];


        // ------------------------------- Tutorial Overview page -------------------------------

        if (window.OpenProject.guardedLocalStorage("openProject-onboardingTour") === "homescreenFinished") {
            var tutorialInstance = new EnjoyHint({
                onEnd: function () {
                    window.OpenProject.guardedLocalStorage(localStorageKey, 'overviewFinished');
                },
                onSkip: function () {
                    window.OpenProject.guardedLocalStorage(localStorageKey, 'skipped');
                }
            });

            tutorialInstance.set(OverviewOnboardingTourSteps);
            tutorialInstance.run();
        };


        // ------------------------------- Tutorial WP page -------------------------------

        if (window.OpenProject.guardedLocalStorage("openProject-onboardingTour") === "overviewFinished") {
            var tutorialInstance = new EnjoyHint({
                onEnd: function () {
                    window.OpenProject.guardedLocalStorage(localStorageKey, 'wpFinished');
                },
                onSkip: function () {
                    window.OpenProject.guardedLocalStorage(localStorageKey, 'skipped');
                    $('.wp-table--details-link, .wp-table-context-menu-link').removeClass('-disabled').unbind('click', preventClickHandler);
                }
            });

            // Wait for the WP table to be ready
            var observer = new MutationObserver(function (mutations, observerInstance) {
                if ($('.work-package--results-tbody')) {
                    observerInstance.disconnect(); // stop observing

                    tutorialInstance.set(WpOnboardingTourSteps);
                    tutorialInstance.run();
                    return;
                }
            });
            observer.observe($('.work-packages-split-view--tabletimeline-side')[0], {
                childList: true,
                subtree: true
            });

        }
    });
}(jQuery));
