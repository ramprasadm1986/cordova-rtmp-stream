var exec = require('cordova/exec');


function videoStreamer() {
}

videoStreamer.prototype.streamRTMP = function(uri,streamName, success, failure) {
    // fire
    exec(
        success,
        failure,
        'VideoStream',
        'streamRTMP',
        [uri,streamName]
    );
};

videoStreamer.prototype.streamRTMPAuth = function(uri,streamName, username, password, success, failure) {
    // fire
    exec(
        success,
        failure,
        'VideoStream',
        'streamRTMPAuth',
        [uri,streamName, username, password]
    );
};

videoStreamer.prototype.streamStop = function(success, failure) {
    // fire
    exec(
        success,
        failure,
        'VideoStream',
        'streamStop',
        []
    );
};

videoStreamer.prototype.echo = function(arg0, success, error) {
    exec(success, error, "VideoStream", "echo", [arg0]);
};

videoStreamer.install = function () {
    if (!window.plugins) {
        window.plugins = {};
    }
    window.plugins.videoStreamer = new videoStreamer();
    return window.plugins.videoStreamer;
};
cordova.addConstructor(videoStreamer.install);
