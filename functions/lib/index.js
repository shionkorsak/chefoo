"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateUserPreferencesClient = exports.fetchUserPreferencesClient = exports.deleteUserAccount = exports.createUserAccount = void 0;
var userAuth_1 = require("./auth/userAuth");
Object.defineProperty(exports, "createUserAccount", { enumerable: true, get: function () { return userAuth_1.createUserAccount; } });
var userAuth_2 = require("./auth/userAuth");
Object.defineProperty(exports, "deleteUserAccount", { enumerable: true, get: function () { return userAuth_2.deleteUserAccount; } });
var userPreference_1 = require("./database/userPreference");
Object.defineProperty(exports, "fetchUserPreferencesClient", { enumerable: true, get: function () { return userPreference_1.fetchUserPreferencesClient; } });
Object.defineProperty(exports, "updateUserPreferencesClient", { enumerable: true, get: function () { return userPreference_1.updateUserPreferencesClient; } });
//# sourceMappingURL=index.js.map