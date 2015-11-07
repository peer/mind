class SanitizeTestCase extends ClassyTestCase
  @testName: 'Sanitize'

  testBasic: ->
    sanitize = new Sanitize
      div: {}
      span:
        class: true
      a: ($, $element, sanitize) =>
        # Allow all content.
        $element.contents()

    @assertEqual sanitize.sanitizeHTML("""<html><div>test</div></html>"""),
      """"""
    @assertEqual sanitize.sanitizeHTML("""<div>test<img src="" />test2</div><b>foo</b>"""),
      """<div>testtest2</div>"""
    @assertEqual sanitize.sanitizeHTML("""<div class="foo"><span class="bar">test</span></div>"""),
      """<div><span class="bar">test</span></div>"""
    @assertEqual sanitize.sanitizeHTML("""<a href=""><div class="foo"><span class="bar">test</span></div></a>"""),
      """<a href=""><div class="foo"><span class="bar">test</span></div></a>"""

  testTree: ->
    sanitize = new Sanitize
      body: ($, $element, sanitize) =>
        sanitize.sanitizeTree $, $element, [
          div: {}
        ,
          span: {}
        ]

    @assertEqual sanitize.sanitizeHTML("""<body></body>"""),
      """<body></body>"""
    @assertEqual sanitize.sanitizeHTML("""<body><div><div></div></div><span></span></body>"""),
      """<body><div></div><span></span></body>"""
    @assertEqual sanitize.sanitizeHTML("""<body><div></div><b></b><span><div></div></span></body>"""),
      """<body><div></div></body>"""
    @assertEqual sanitize.sanitizeHTML("""<body><span></span><div></div></body>"""),
      """<body></body>"""

    sanitize = new Sanitize
      body: ($, $element, sanitize) =>
        sanitize.sanitizeTree $, $element, [
          div: {}
          span: {}
        ]

    @assertEqual sanitize.sanitizeHTML("""<body></body>"""),
      """<body></body>"""
    @assertEqual sanitize.sanitizeHTML("""<body><div><div></div></div><span></span></body>"""),
      """<body><div></div></body>"""
    @assertEqual sanitize.sanitizeHTML("""<body><div></div><b></b><span><div></div></span></body>"""),
      """<body><div></div></body>"""
    @assertEqual sanitize.sanitizeHTML("""<body><span></span><div></div></body>"""),
      """<body><span></span></body>"""

    sanitize = new Sanitize
      body: ($, $element, sanitize) =>
        sanitize.sanitizeTree $, $element,
          div: {}
          span: {}

    @assertEqual sanitize.sanitizeHTML("""<body></body>"""),
      """<body></body>"""
    @assertEqual sanitize.sanitizeHTML("""<body><div><div></div></div><span></span></body>"""),
      """<body><div></div><span></span></body>"""
    @assertEqual sanitize.sanitizeHTML("""<body><div></div><b></b><span><div></div></span></body>"""),
      """<body><div></div><span></span></body>"""
    @assertEqual sanitize.sanitizeHTML("""<body><span></span><div></div></body>"""),
      """<body><span></span><div></div></body>"""

    sanitize = new Sanitize
      body: ($, $element, sanitize) =>
        sanitize.sanitizeTree $, $element,
          div:
            attributes:
              class: true
            children:
              span: {}
              a: ($, $element, sanitize) =>
                # Allow all content.
                $element.contents()

    @assertEqual sanitize.sanitizeHTML("""<body><div class="foo"><a href=""><b></b></a><span></span></div></body>"""),
      """<body><div class="foo"><a href=""><b></b></a><span></span></div></body>"""
    @assertEqual sanitize.sanitizeHTML("""<body><div class="foo" ref="1"><a href=""><b></b></a><span ref="2"></span></div></body>"""),
      """<body><div class="foo"><a href=""><b></b></a><span></span></div></body>"""

ClassyTestCase.addTest new SanitizeTestCase()
