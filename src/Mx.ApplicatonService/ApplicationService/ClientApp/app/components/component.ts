import { Component } from '@angular/core';

export class ResourceComponent {
    key: "0";
    mode: "create";
    dataService: {};
    validatorService: {};
    model: {};

    constructor() {
        this.key = "0";
        this.mode = "create";
    }

    validate() {
        var results = this.validatorService.validate(this.model);
        if (results) {
            return false;
        }
        return true;
    }

    load() {
        if (this.mode === "create") {
        }

        if (this.model === "update") {
        }
    }

    save() {
        if (this.validate(this.model) {
            if (this.mode === "create") {
                this.dataService.Create(this.model);
            }
            if (this.mode === "update") {
                this.dataService.Update(this.key, this.model);
            }
        }
    }
}