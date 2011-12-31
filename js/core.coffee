# HACK!!
DR = new DOMRedactor()
CORE_CSS = ""
DS_CSS = ""

setupIframe = (doc, styles...) ->
  for css in styles
    stylesheet = $("<style>#{css}</style>")
    doc.find('head').append(stylesheet)  


# Render
render = (doc, html) ->
  doc.find('body').html(html)



skeleton = (doc, html) ->
  bodyDOM = doc.find('body')[0]

  render(doc, html)

  DR.redact bodyDOM, () ->
    DR.render bodyDOM,
      'img_context': (ctx, w, h) ->
        ctx.fillStyle = "rgb(240,240,240)"
        ctx.fillRect(0, 0, w, h)

        ctx.fillStyle = "rgb(248,248,248)"
        ctx.fillRect(10, 10, w-20, h-20)

        # Or maybe an image
        # ctx.fillStyle = "rgb(240,240,240)"
        # ctx.fillRect(0, 0, w, h)
        
        # var x = w/2-IMG.width/2
        # var y = h/2-IMG.height/2
        # ctx.drawImage(IMG,x,y);


# Scroll 2 scrollable areas together
setupJointScroll = (a, b) ->
  a.bind 'scroll', () ->
    b.scrollTop a.scrollTop()

  b.bind 'scroll', () ->
    a.scrollTop b.scrollTop()


init = () ->
  normalDOM   = $('#normal').contents()
  skeletonDOM = $('#skeleton').contents()
  normalWin   = $($('#normal')[0].contentWindow)
  skeletonWin = $($('#skeleton')[0].contentWindow)
  sourceDOM   = $('#source')

  setupJointScroll(normalWin, skeletonWin)

  setupIframe(normalDOM,   CORE_CSS, DS_CSS)
  setupIframe(skeletonDOM, CORE_CSS, DS_CSS)

  run = () ->
    html = sourceDOM.val()
    render(normalDOM, html)
    skeleton(skeletonDOM, html)

  sourceDOM.val("<h1>Hello</h1><p>what!</p>")
  sourceDOM.val(SOURCE)
  sourceDOM.bind('keydown change',run)

  run()


IMG = null
CSS = ""
SOURCE = ""

$(document).ready () ->
  resize = () ->
    bodyDOM = $('.skeleton iframe').contents().find('body')
    if !bodyDOM.find('.temp-height')[0]
      bodyDOM.contents().wrapAll('<div class="temp-height"></div>')          

    th = bodyDOM.find('.temp-height').height()
    $('.container').height(th+70)


  toggle = (e, switchTo) ->
    console.log(switchTo)

    if switchTo == "preview"
      $('.buttons .btn-source').removeClass('active')
      $('.buttons .btn-preview').addClass('active')
      $('.source').hide()
      $('.preview').show()

      resize()   
    else
      $('.buttons .btn-source').addClass('active')
      $('.buttons .btn-preview').removeClass('active')
      $('.source').show()
      $('.preview').hide()

      $('.container').height(450)


  $('.buttons .btn-source').click () ->
    toggle(null, "source")

  $('.buttons .btn-preview').click () ->
    toggle(null, "preview")


  $(window).resize(resize)


  go = () ->
    $.get 'pages/test1.html', (data) ->
      # HACK
      SOURCE = data
      CORE_CSS = ""
      $.get 'dom_redactor.css', (data) ->
        DS_CSS = data
        init()
        toggle(null, "preview")

  # HACK!!!
  IMG = new Image()
  IMG.onload  = () ->
    go()

  IMG.onerror = () ->
    IMG=null
    go()

  IMG.src = "pages/cancel.png"