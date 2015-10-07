function Vkontakte() {
  // Does nothing
};
Vkontakte.prototype.init = function(appId, successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, 'Vkontakte', 'initWithApp', [appId]);
};

Vkontakte.prototype.login = function(permissions, successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, 'Vkontakte', 'login', [permissions]);
};

module.exports = new Vkontakte();
