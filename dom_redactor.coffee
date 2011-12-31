class DOMRedactor
  WALK_IGNORE_REGEXP = /SCRIPT/
  TEXT_IGNORE_REGEXP = /H1|H2|H3|H4|H5|H6/
  DOM_TEXT_NODE    = 3
  DOM_ELEMENT_NODE = 1

  SPECIAL_CHARS = /[\t\n\r]/

  # The less we have here the better it'll gzip
  # NOTE: This is a best guess, it can't be exact and doesn't pretend to be
  # This should be loaded from a 
  LETTER_MAPPINGS =
    "i": /[fijlt\)\(:;]/
    "a": /[abcdeghkmnopqrsuvwxyz]/
    "I": /([IJ]|[1]|[,./])/
    "A": /([ABCDEFGHKLMNOPQRSTUVWXYZ]|[234567890])/

  ##
  ## Private
  ##

  # Walk the DOM calling the callback for each node found
  walkDOM = (node, callback, withText=false) ->
    for node in node.childNodes
      rslt = callback(node)
      if !rslt
        continue

      if node.childNodes?.length
        walkDOM(node, callback, withText)
    null


  wrapDOM = (node, tagName) ->
    wrapper = @document.createElement(tagName)
    wrapper.appendChild(node.cloneNode(true))
    node.parentNode.replaceChild(wrapper, node)
    return wrapper


  hasCanvas = () ->
    elem = @document.createElement('canvas')
    return (elem.getContext && elem.getContext('2d'))


  # TODO: <http://aaronrussell.co.uk/legacy/cross-browser-support-for-inline-block/>
  addInlineHack = () ->
    #* html .myclass { display:inline; }  /* for IE 6 */
    #* + html .myclass { display:inline; }  /* for IE 7 */

  ###
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
  ###

  ##
  ## Public
  ##
  constructor: (window=window, document=document) ->
    # For node.js (doesn't work atm)
    @window   = window
    @document = document


  redact: (startNode, callback) ->
    blocking = 0

    walkDOM startNode, (node) ->     
      if node.nodeName.match(WALK_IGNORE_REGEXP)
        return false

      if node.nodeName && node.nodeName.match(TEXT_IGNORE_REGEXP)
        return false

      # Change the contents of the text nodes.
      if node.nodeType == DOM_TEXT_NODE
        # Don't change whitespace
        return true if node.nodeValue.match(/^\s+$/)

        newNodeValue = ""
        nodeValue = node.nodeValue

        for i in [0...nodeValue.length]
          letter = nodeValue[i]

          if letter.match(SPECIAL_CHARS)
            newNodeValue += letter
          else if letter == " "
            newNodeValue += " "
          else
            # Just for safety incase nothing matches
            newValue = "a"

            # Match against the letter matches
            for substituteLetter,regex of LETTER_MAPPINGS
              if letter.match(regex)
                newValue = substituteLetter
                break

            newNodeValue += newValue
        node.nodeValue = newNodeValue
      else if node.nodeType == DOM_ELEMENT_NODE
        if node.tagName == "IMG" && Image?
          src = node.getAttribute('src')

          fun = () ->
            node.setAttribute("data-orig-size",   "#{img.width}x#{img.height}")
            node.setAttribute("src", "#")
            #console.log node
            blocking--
            if blocking == 0
              #console.log "DONE"
              callback()

          img = new Image() # Create new img element  
          img.onload = fun
          img.onerror = () ->
            blocking--
            if blocking == 0
              callback()
          img.src = src

          blocking++
        else
          # Remove any title and null hrefs
          node.removeAttribute('title')
          node.setAttribute('href', "#") if node.hasAttribute('href')

      return true

    if blocking < 1
      callback()
  

  # Adds additional element for better styling
  # opts:
  #   img_color   - color for the images
  #   img_context - canvas context whih gets generated into an image
  render: (node, opts={}, callback=null) ->
    walkDOM node, (node) ->

      # TEXT NODE
      if node.nodeType == DOM_TEXT_NODE
        # Ignore whitespace
        return true if node.nodeValue.match(/^\s+$/)

        # Wrap each text node
        wrapDOM(node, 'dswrapper')
      else
        if node.tagName == "IMG" && Image?
          size = node.getAttribute("data-orig-size")
          if size?
            [w,h] = size.split('x')

            if hasCanvas()
              canvas = @document.createElement('canvas')
              canvas.setAttribute 'width',  w
              canvas.setAttribute 'height', h
              ctx    = canvas.getContext('2d')

              if opts['img_context']?
                if typeof(opts['img_context']) != "function"
                  throw "'img_context' not a function"

                opts['img_context'](ctx, w, h)
              else
                ctx.fillStyle = opts['img_color'] ? "rgb(238,238,238)"
                ctx.fillRect(0, 0, w, h)

              node.setAttribute "src", canvas.toDataURL()
            else
              # TODO: This need to be handled differently
              size = node.getAttribute("data-orig-size")
              [iw,ih] = size.split('x')
            
              w = if node.style.width.match(/^(auto|)$/)  then "100%" else node.style.width
              h = if node.style.height.match(/^(auto|)$/) then "100%" else node.style.height

              node.style.maxWidth  = iw
              node.style.maxHeight = ih

              node.className += " blabla "
              newClass("blabla", "width: #{w}; height: #{h};")

        else if node.nodeType == DOM_ELEMENT_NODE
          if node.hasAttribute('href')
            node.setAttribute('href', "javascript:void(0);")

      return true

    node.className = node.className + " dom-skeleton"


if !window?.DOMRedactor = DOMRedactor 
  # Hoping to support node.
  module.exports = DOMRedactor
