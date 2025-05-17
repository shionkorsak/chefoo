"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.updatePreferenceAI = exports.updateClientPreferences = exports.deleteUserAccount = exports.createUserAccount = void 0;
const https_1 = require("firebase-functions/https");
const personality_1 = require("./ai/personality");
var userAuth_1 = require("./auth/userAuth");
Object.defineProperty(exports, "createUserAccount", { enumerable: true, get: function () { return userAuth_1.createUserAccount; } });
var userAuth_2 = require("./auth/userAuth");
Object.defineProperty(exports, "deleteUserAccount", { enumerable: true, get: function () { return userAuth_2.deleteUserAccount; } });
var userPreference_1 = require("./database/userPreference");
Object.defineProperty(exports, "updateClientPreferences", { enumerable: true, get: function () { return userPreference_1.updateClientPreferences; } });
exports.updatePreferenceAI = (0, https_1.onCallGenkit)(personality_1.updatePreference);
//# sourceMappingURL=index.js.map