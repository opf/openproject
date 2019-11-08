/**
 * @private
 */
export default class BimServerApiPromise {
	constructor(counter = null) {
		this.isDone = false;
		this.chains = [];
		this.callback = null;
		this.counter = counter;
	}

	done(callback) {
		if (this.isDone) {
			callback();
		} else {
			if (this.callback != null) {
				if (this.callback instanceof Array) {
					this.callback.push(callback);
				} else {
					this.callback = [this.callback, callback];
				}
			} else {
				this.callback = callback;
			}
		}
		return this;
	}

	inc() {
		if (this.counter == null) {
			this.counter = 0;
		}
		this.counter++;
	}

	dec() {
		if (this.counter == null) {
			this.counter = 0;
		}
		this.counter--;
		if (this.counter === 0) {
			this.done = true;
			this.fire();
		}
	}

	fire() {
		if (this.isDone) {
			console.log("Promise already fired, not triggering again...");
			return;
		}
		this.isDone = true;
		if (this.callback != null) {
			if (this.callback instanceof Array) {
				this.callback.forEach((cb) => {
					cb();
				});
			} else {
				this.callback();
			}
		}
	}

	chain(otherPromise) {
		let promises;
		if (otherPromise instanceof Array) {
			promises = otherPromise;
		} else {
			promises = [otherPromise];
		}
		promises.forEach((promise) => {
			if (!promise.isDone) {
				this.chains.push(promise);
				promise.done(() => {
					for (let i = this.chains.length - 1; i >= 0; i--) {
						if (this.chains[i] == promise) {
							this.chains.splice(i, 1);
						}
					}
					if (this.chains.length === 0) {
						this.fire();
					}
				});
			}
		});
		if (this.chains.length === 0) {
			this.fire();
		}
	}
}