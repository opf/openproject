
export class DemoService {

    constructor() {
        console.log("start");
    }

    method() {
    }

}

angular.module('openproject').service("demoService", DemoService);
