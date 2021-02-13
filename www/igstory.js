
var exec = require('cordova/exec');

var PLUGIN_NAME = 'IGStory';

var IGStory = {
  shareToStory: function(opts, cb, err) {
    exec(cb, err, PLUGIN_NAME, 'shareToStory', [opts.backgroundImage, opts.stickerImage, opts.attributionURL, opts.backgroundTopColor, opts.backgroundBottomColor, opts.isVideo]);
  },
  shareImageToStory: function(backgroundImage, cb, err) {
    exec(cb, err, PLUGIN_NAME, 'shareImageToStory', [backgroundImage]);
  },
  shareMediaToStory: function(mediaBase64, cb, err) {
    exec(cb, err, PLUGIN_NAME, 'shareMediaToStory', [mediaBase64]);
  }
};

module.exports = IGStory;
