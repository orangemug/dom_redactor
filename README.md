# README - WORK IN PROGRESS (IT MIGHT NOT WORK ATM)

Hiding content whilst keeping the document structure, best to checkout the demo [here]()


## Usage

There are two steps firstly processing the content, which will eventually be done server side (will be releasing this shortly). This step basically replaces text contents with repeating charaters and also removes the image tags and replaces them with just the sizing information.

    var dr = new DOMRedactor;
    var dom = document.getElementById('content');
    dr.redact(dom);


The second step add some extra tags which allow for better styling and build the images from the information stored in the redact step.

    var dr = new DOMRedactor;
    var dom = document.getElementById('content')
    dr.render(bodyDOM);


The above step adds in a load of custom tags (`<dswrapper></dswrapper>`) for styling the content, an example stylesheet is included [here]()


## How it works

TODO - More detail description on whats going on with examples


## Dependicies

None


## Build

To build simply run the following from the base directory.

    coffee --compile dom_redactor.coffee


## TODO

 * Finalize the API
 * Tidy the example page
 * Build a work around for browsers which don't support data-urls
 * Define browser compatibility.
 * Add ruby/php lib for the redact process.
 * Prep code for the google closure compiler advanced optimizations.
 * Support greater charater set
