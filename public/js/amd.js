/*
amd.js

A globally loaded "module" providing a minimal AMD system.
*/

class AMD {
    constructor() {
        this.modules = {};
        this.root = '';
    }

    async addRunModule(name, fun) {
        const result = await fun();
        this.addModule(name, result);
    }

    addModule(name, value) {
       this.modules[name] = value;
    }

    getModule(name) {
        return this.modules[name];
    }

    async fetchAndEvalDependency(dependency) {
        const url = new URL(window.location.origin);
        url.pathname = `${this.root}/${dependency}.js`;
        const resource = await fetch(url);
        const jsCode = await resource.text();
        // For now, just code, but we'll abstract soon.

        // Note that the "module" defined in resource will 
        // be registered as soon as the code is run.
        const code = `"use strict"; window.amd.addRunModule("${dependency}", () => {return ${jsCode}});`;
        eval?.(code);
    }

    async fetchDependencies(dependencies) {
        dependencies.forEach((d) => {
            this.fetchAndEvalDependency(d);
        });

        return new Promise((resolve, reject) => {
            let tries = 10;
            const loop = () => {
                if (tries === 0) {
                    reject(new Error('Could not load a dependency'));
                }
                if (dependencies.every((d) => {
                    return (d in this.modules);
                })) {
                    resolve();
                    return;
                }

                tries -= 1;
                window.setTimeout(() => {
                    loop();
                }, 100);
            }
            loop();
        });
    }

    async resolveDependencies(dependencies) {
        const resolved = [];
        const needed = [];

        for (const d of dependencies) {
            if (!(d in this.modules)) {
                // throw new Error(`dependency ${d} is not defined`);
                needed.push(d);
            } else {
                resolved.push(this.modules[d]);
            }
        }

        if (needed.length > 0) {
            await this.fetchDependencies(needed);
            // needed.push(...needed);
            for (const d of needed) {
                resolved.push(this.modules[d]);
            }
        }

        return resolved;
    }

    async define(dependencies, moduleDefinition) {
        // for now, we don't do any fancy inspection of parameters,
        // which would allow us to ignore "name".

        // First we resolve all the dependencies.
        // In this iteration, we do NOT fetch them, we assume they are defined.
    
        const resolved = await this.resolveDependencies(dependencies);

        try {
            const moduleResult = moduleDefinition(...resolved);
            return moduleResult;
        } catch (ex) {
            throw new Error(`error loading module definition "${name}": ${ex.message}`)
        }
    }

    async require(dependencies, implementation) {
        const resolved = await this.resolveDependencies(dependencies);
        try {
            implementation(...resolved);
        } catch (ex) {
            throw new Error(`error running code: ${ex.message}`)
        }
    }
}

function initializeAMD(global) {
    if (global.amd) {
        return;
    }

    global.amd = new AMD();
}

initializeAMD(window);
