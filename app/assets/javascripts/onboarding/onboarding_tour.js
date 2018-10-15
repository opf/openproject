(function ($) {
    $(function() {
        // ------------------------------- Global -------------------------------
        window.tutorialInstance;
        window.preventClickHandler = function (e) {
            e.preventDefault();
            e.stopPropagation();
        };
        window.waitForElement = function(element, container, execFunction) {
            // Wait for the element to be ready
            var observer = new MutationObserver(function (mutations, observerInstance) {
                if ($(element).length) {
                    observerInstance.disconnect(); // stop observing
                    execFunction();
                    return;
                }
            });
            observer.observe($(container)[0], {
                childList: true,
                subtree: true
            });
        }


        var storageKey = 'openProject-onboardingTour';
        var currentTourPart = sessionStorage.getItem(storageKey);
        var url = new URL(window.location.href);

        // ------------------------------- Initial start -------------------------------
        // Do not show the tutorial on mobile
        if(! /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) ) {

            // Start after the intro modal (language selection)
            // This has to be changed once the project selection is implemented
            if (url.searchParams.get("first_time_user")) {
                currentTourPart = '';
                sessionStorage.setItem(storageKey, 'readyToStart');

                // Start automatically when the language selection is closed
                $('.op-modal--modal-close-button').click(function () {
                    initializeTour('startOverviewTour', '.widget-box--blocks--buttons .button');
                    startTour(homescreenOnboardingTourSteps);
                });
            }

            // ------------------------------- Tutorial Homescreen page -------------------------------
            if (currentTourPart === "readyToStart") {
                initializeTour('startOverviewTour', '.widget-box--blocks--buttons .button');
                startTour(homescreenOnboardingTourSteps);
            }

            // ------------------------------- Tutorial Overview page -------------------------------
            if (currentTourPart === "startOverviewTour") {
                if ($('.backlogs-menu-item').length > 0) {
                    initializeTour('startBacklogsTour');
                    startTour(scrumOverviewOnboardingTourSteps);
                } else {
                    initializeTour('startWpTour');
                    startTour(overviewOnboardingTourSteps);
                }
            }

            // ------------------------------- Tutorial Backlogs page -------------------------------
            if (currentTourPart === "startBacklogsTour") {
                initializeTour('startTaskBoardTour', ".backlog .menu a:not('.show_task_board')");
                startTour(scrumBacklogsTourSteps);
            }

            // ------------------------------- Tutorial Task Board page -------------------------------
            if (currentTourPart === "startTaskBoardTour") {
                initializeTour('startWpTour');
                startTour(scrumTaskBoardTourSteps);
            }

            // ------------------------------- Tutorial WP page -------------------------------
            if (currentTourPart === "startWpTour") {
                initializeTour('wpFinished', '.wp-table--details-link, .wp-table-context-menu-link, .wp-table--cell-span');

                waitForElement('.work-package--results-tbody', '.work-packages-split-view--tabletimeline-side', function() {
                    startTour(wpOnboardingTourSteps);
                });
            }
        }

        function initializeTour(storageValue, disabledElements) {
            tutorialInstance = new EnjoyHint({
                onEnd: function () {
                    sessionStorage.setItem(storageKey, storageValue);
                },
                onSkip: function () {
                    sessionStorage.setItem(storageKey, 'skipped');
                    if (disabledElements) jQuery(disabledElements).removeClass('-disabled').unbind('click', preventClickHandler);
                }
            });
        }

        function startTour(steps) {
            tutorialInstance.set(steps);
            tutorialInstance.run();
        }

    });
}(jQuery));
