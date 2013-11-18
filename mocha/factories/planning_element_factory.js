var planningElementFactory = {
	create: function (options) {
		return jQuery.extend(Object.create(Timeline.PlanningElement), options);
	}
}