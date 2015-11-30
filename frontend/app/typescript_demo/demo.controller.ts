import {DemoService} from "./demo.service";

class DemoController {

    constructor(demoService: DemoService) {
        demoService.method();
    }

}

angular.module('openproject').controller("DemoController", DemoController);
