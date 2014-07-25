module.exports = function(config) {
  config.set({
    //logLevel: config.LOG_DEBUG,
    basePath: '.',
    frameworks: ["jasmine", "traceur", "requirejs"],

    traceurPreprocessor: {
      options: {
        modules: 'amd',
//        types: true,
//        typeAssertions: true,
//        typeAssertionModule: 'assert',
        annotations: true,
        sourceMap: true
        /**
         * Someday blockBinding would be nice, but for now it compiles to nasty
         * ES5 code (everything in a closure)
         */
        // blockBinding: true
      }
    },

    // list of files / patterns to load in the browser
    // all tests must be 'included', but all other libraries must be 'served' and
    // optionally 'watched' only.
    files: [
      {pattern: "test/out/helloworld.js", included: false},
      {pattern: "test/*.spec.js", included: false},
      "test/test-main.js"
    ],

    exclude: [

    ],

    autoWatch: false,

    // If browser does not capture in given timeout [ms], kill it
    captureTimeout: 120000,
    // Time for dart2js to run on Travis... [ms]
    browserNoActivityTimeout: 1500000,

    browsers: ['Chrome'],

    preprocessors: {
      "test/out/helloworld.js" : ["traceur"],
      "test/*.spec.js" : ["traceur"]
    }
  });
};
