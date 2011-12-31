(function() {
  var DOMRedactor;

  DOMRedactor = (function() {
    var DOM_ELEMENT_NODE, DOM_TEXT_NODE, LETTER_MAPPINGS, SPECIAL_CHARS, TEXT_IGNORE_REGEXP, WALK_IGNORE_REGEXP, addInlineHack, hasCanvas, walkDOM, wrapDOM;

    WALK_IGNORE_REGEXP = /SCRIPT/;

    TEXT_IGNORE_REGEXP = /H1|H2|H3|H4|H5|H6/;

    DOM_TEXT_NODE = 3;

    DOM_ELEMENT_NODE = 1;

    SPECIAL_CHARS = /[\t\n\r]/;

    LETTER_MAPPINGS = {
      "i": /[fijlt\)\(:;]/,
      "a": /[abcdeghkmnopqrsuvwxyz]/,
      "I": /([IJ]|[1]|[,./])/,
      "A": /([ABCDEFGHKLMNOPQRSTUVWXYZ]|[234567890])/
    };

    walkDOM = function(node, callback, withText) {
      var rslt, _i, _len, _ref, _ref2;
      if (withText == null) withText = false;
      _ref = node.childNodes;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        node = _ref[_i];
        rslt = callback(node);
        if (!rslt) continue;
        if ((_ref2 = node.childNodes) != null ? _ref2.length : void 0) {
          walkDOM(node, callback, withText);
        }
      }
      return null;
    };

    wrapDOM = function(node, tagName) {
      var wrapper;
      wrapper = this.document.createElement(tagName);
      wrapper.appendChild(node.cloneNode(true));
      node.parentNode.replaceChild(wrapper, node);
      return wrapper;
    };

    hasCanvas = function() {
      var elem;
      elem = this.document.createElement('canvas');
      return elem.getContext && elem.getContext('2d');
    };

    addInlineHack = function() {};

    /*
      # CREDIT: <http://snipplr.com/view/13523/getcomputedstyle-for-ie/>
      if !window.getComputedStyle
        window.getComputedStyle = (el, pseudo) ->
          this.el = el
          this.getPropertyValue = (prop) ->
            re = /(\-([a-z]){1})/g
            if prop == 'float'
              prop = 'styleFloat'
    
            if re.test(prop)
              prop = prop.replace re, () ->
                return arguments[2].toUpperCase()
    
            return el.currentStyle[prop] ? null
    
          return this
    */

    function DOMRedactor(window, document) {
      if (window == null) window = window;
      if (document == null) document = document;
      this.window = window;
      this.document = document;
    }

    DOMRedactor.prototype.redact = function(startNode, callback) {
      var blocking;
      blocking = 0;
      walkDOM(startNode, function(node) {
        var fun, i, img, letter, newNodeValue, newValue, nodeValue, regex, src, substituteLetter, _ref;
        if (node.nodeName.match(WALK_IGNORE_REGEXP)) return false;
        if (node.nodeName && node.nodeName.match(TEXT_IGNORE_REGEXP)) return false;
        if (node.nodeType === DOM_TEXT_NODE) {
          if (node.nodeValue.match(/^\s+$/)) return true;
          newNodeValue = "";
          nodeValue = node.nodeValue;
          for (i = 0, _ref = nodeValue.length; 0 <= _ref ? i < _ref : i > _ref; 0 <= _ref ? i++ : i--) {
            letter = nodeValue[i];
            if (letter.match(SPECIAL_CHARS)) {
              newNodeValue += letter;
            } else if (letter === " ") {
              newNodeValue += " ";
            } else {
              newValue = "a";
              for (substituteLetter in LETTER_MAPPINGS) {
                regex = LETTER_MAPPINGS[substituteLetter];
                if (letter.match(regex)) {
                  newValue = substituteLetter;
                  break;
                }
              }
              newNodeValue += newValue;
            }
          }
          node.nodeValue = newNodeValue;
        } else if (node.nodeType === DOM_ELEMENT_NODE) {
          if (node.tagName === "IMG" && (typeof Image !== "undefined" && Image !== null)) {
            src = node.getAttribute('src');
            fun = function() {
              node.setAttribute("data-orig-size", "" + img.width + "x" + img.height);
              node.setAttribute("src", "#");
              blocking--;
              if (blocking === 0) return callback();
            };
            img = new Image();
            img.onload = fun;
            img.onerror = function() {
              blocking--;
              if (blocking === 0) return callback();
            };
            img.src = src;
            blocking++;
          } else {
            node.removeAttribute('title');
            if (node.hasAttribute('href')) node.setAttribute('href', "#");
          }
        }
        return true;
      });
      if (blocking < 1) return callback();
    };

    DOMRedactor.prototype.render = function(node, opts, callback) {
      if (opts == null) opts = {};
      if (callback == null) callback = null;
      walkDOM(node, function(node) {
        var canvas, ctx, h, ih, iw, size, w, _ref, _ref2, _ref3;
        if (node.nodeType === DOM_TEXT_NODE) {
          if (node.nodeValue.match(/^\s+$/)) return true;
          wrapDOM(node, 'dswrapper');
        } else {
          if (node.tagName === "IMG" && (typeof Image !== "undefined" && Image !== null)) {
            size = node.getAttribute("data-orig-size");
            if (size != null) {
              _ref = size.split('x'), w = _ref[0], h = _ref[1];
              if (hasCanvas()) {
                canvas = this.document.createElement('canvas');
                canvas.setAttribute('width', w);
                canvas.setAttribute('height', h);
                ctx = canvas.getContext('2d');
                if (opts['img_context'] != null) {
                  if (typeof opts['img_context'] !== "function") {
                    throw "'img_context' not a function";
                  }
                  opts['img_context'](ctx, w, h);
                } else {
                  ctx.fillStyle = (_ref2 = opts['img_color']) != null ? _ref2 : "rgb(238,238,238)";
                  ctx.fillRect(0, 0, w, h);
                }
                node.setAttribute("src", canvas.toDataURL());
              } else {
                size = node.getAttribute("data-orig-size");
                _ref3 = size.split('x'), iw = _ref3[0], ih = _ref3[1];
                w = node.style.width.match(/^(auto|)$/) ? "100%" : node.style.width;
                h = node.style.height.match(/^(auto|)$/) ? "100%" : node.style.height;
                node.style.maxWidth = iw;
                node.style.maxHeight = ih;
                node.className += " blabla ";
                newClass("blabla", "width: " + w + "; height: " + h + ";");
              }
            }
          } else if (node.nodeType === DOM_ELEMENT_NODE) {
            if (node.hasAttribute('href')) {
              node.setAttribute('href', "javascript:void(0);");
            }
          }
        }
        return true;
      });
      return node.className = node.className + " dom-skeleton";
    };

    return DOMRedactor;

  })();

  if (!(typeof window !== "undefined" && window !== null ? window.DOMRedactor = DOMRedactor : void 0)) {
    module.exports = DOMRedactor;
  }

}).call(this);
