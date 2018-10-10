(function ($) {
    $(function() {
        var preventClickHandler = function(e) {
            e.preventDefault();
            e.stopPropagation();
        };
        var storageKey = 'openProject-onboardingTour';
        var currentTourPart = sessionStorage.getItem(storageKey);
        var url = new URL(window.location.href);

        var homescreenOnboardingTourSteps = [
            {
                'next #logo' : I18n.t('js.onboarding.steps.welcome'),
                'showSkip' : false
            },
            {
                "description" : I18n.t('js.onboarding.steps.project_selection'),
                'selector' : '.widget-box.projects .widget-box--arrow-links',
                'event' : 'click',
                'showSkip' : false,
                'containerClass' : '-dark',
                onBeforeStart: function () {
                    $('.enjoyhint').toggleClass('-clickable', true);
                }
            }
        ];

        var overviewOnboardingTourSteps = [
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

        var wpOnboardingTourSteps = [
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

        // Start after the intro modal (language selection)
        // This has to be changed once the project selection is implemented
        if(url.searchParams.get("first_time_user")) {
            sessionStorage.setItem(storageKey, 'readyToStart');

            // Start automatically when the language selection is closed
            $('.op-modal--modal-close-button').click(function() {
                startTour(homescreenOnboardingTourSteps, 'homescreenFinished')
            });
        }

        // ------------------------------- Tutorial Homescreen page -------------------------------
        if (currentTourPart === "readyToStart") {
            startTour(homescreenOnboardingTourSteps, 'homescreenFinished');
        };

        // ------------------------------- Tutorial Overview page -------------------------------
        if (currentTourPart === "homescreenFinished") {
            startTour(overviewOnboardingTourSteps, 'overviewFinished');
        };

        // ------------------------------- Tutorial WP page -------------------------------
        if (currentTourPart === "overviewFinished") {
            var tutorialInstance = new EnjoyHint({
                onEnd: function () {
                    sessionStorage.setItem(storageKey, 'wpFinished');
                },
                onSkip: function () {
                    sessionStorage.setItem(storageKey, 'skipped');
                    $('.wp-table--details-link, .wp-table-context-menu-link').removeClass('-disabled').unbind('click', preventClickHandler);
                }
            });

            // Wait for the WP table to be ready
            var observer = new MutationObserver(function (mutations, observerInstance) {
                if ($('.work-package--results-tbody')) {
                    observerInstance.disconnect(); // stop observing

                    tutorialInstance.set(wpOnboardingTourSteps);
                    tutorialInstance.run();
                    return;
                }
            });
            observer.observe($('.work-packages-split-view--tabletimeline-side')[0], {
                childList: true,
                subtree: true
            });

        }

        function startTour(steps, storageValue) {
            var tutorialInstance = new EnjoyHint({
                onEnd: function () {
                    sessionStorage.setItem(storageKey, storageValue);
                },
                onSkip: function () {
                    sessionStorage.setItem(storageKey, 'skipped');
                }
            });

            tutorialInstance.set(steps);
            tutorialInstance.run();
        }
    });
}(jQuery));
