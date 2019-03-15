(function ($) {
    $(function() {
        window.boardTourSteps = [
            {
                'next .board-view-menu-item': I18n.t('js.onboarding.boards.overview'),
                'showSkip': false,
                'nextButton': {text: I18n.t('js.onboarding.buttons.next')},
                onNext: function () {
                    $('.board-view-menu-item ~ .toggler')[0].click();
                    $('.main-menu--children-sub-item')[0].click();
                }
            },
            {
                'next .board-list--container': I18n.t('js.onboarding.boards.lists'),
                'showSkip': false,
                'nextButton': {text: I18n.t('js.onboarding.buttons.next')},
                'timeout': function() {
                    return new Promise(function(resolve) {
                        waitForElement('.board-list--container', '#content', function() {
                            resolve();
                        });
                    });
                }
            },
            {
                'next .board-list--card-dropdown-button': I18n.t('js.onboarding.boards.add'),
                'showSkip': false,
                'nextButton': {text: I18n.t('js.onboarding.buttons.next')},
            },
            {
                'next .boards-list--container': I18n.t('js.onboarding.boards.drag'),
                'showSkip': false,
                'nextButton': {text: I18n.t('js.onboarding.buttons.next')},
                'containerClass': '-dark -hidden-arrow',
                onNext: function () {
                    $('.main-menu--arrow-left-to-project')[0].click();
                }
            }
        ];
    });
}(jQuery))
