import { Application } from '@hotwired/stimulus';
import Boards_controller from './controllers/boards_controller';
import Hot_message_controller from './controllers/hot_message_controller';
import List_controller from './controllers/list_controller';
import Split_view_controller from './controllers/split_view_controller';
import { Turbo } from '@hotwired/turbo-rails';

const stimulus = Application.start(document.documentElement);
// eslint-disable-next-line @typescript-eslint/no-explicit-any,@typescript-eslint/no-unsafe-member-access
(window as any).Stimulus = stimulus;

stimulus.register('boards', Boards_controller);
stimulus.register('hot_message', Hot_message_controller);
stimulus.register('list', List_controller);
stimulus.register('split_view', Split_view_controller);

Turbo.session.drive = false;
