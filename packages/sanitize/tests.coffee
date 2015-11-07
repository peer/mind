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

    @assertEqual sanitize.sanitizeHTML("""<content><div>test</div></content>"""),
      """"""
    @assertEqual sanitize.sanitizeHTML("""<div>test<img src="" />test2</div><b>foo</b>"""),
      """<div>testtest2</div>"""
    @assertEqual sanitize.sanitizeHTML("""<div class="foo"><span class="bar">test</span></div>"""),
      """<div><span class="bar">test</span></div>"""
    @assertEqual sanitize.sanitizeHTML("""<a href=""><div class="foo"><span class="bar">test</span></div></a>"""),
      """<a href=""><div class="foo"><span class="bar">test</span></div></a>"""

  testTree: ->
    sanitize = new Sanitize
      content: ($, $element, sanitize) =>
        sanitize.sanitizeTree $, $element, [
          div: {}
        ,
          span: {}
        ]

    @assertEqual sanitize.sanitizeHTML("""<content></content>"""),
      """<content></content>"""
    @assertEqual sanitize.sanitizeHTML("""<content><div><div></div></div><span></span></content>"""),
      """<content><div></div><span></span></content>"""
    @assertEqual sanitize.sanitizeHTML("""<content><div></div><b></b><span><div></div></span></content>"""),
      """<content><div></div></content>"""
    @assertEqual sanitize.sanitizeHTML("""<content><span></span><div></div></content>"""),
      """<content></content>"""

    sanitize = new Sanitize
      content: ($, $element, sanitize) =>
        sanitize.sanitizeTree $, $element, [
          div: {}
          span: {}
        ]

    @assertEqual sanitize.sanitizeHTML("""<content></content>"""),
      """<content></content>"""
    @assertEqual sanitize.sanitizeHTML("""<content><div><div></div></div><span></span></content>"""),
      """<content><div></div></content>"""
    @assertEqual sanitize.sanitizeHTML("""<content><div></div><b></b><span><div></div></span></content>"""),
      """<content><div></div></content>"""
    @assertEqual sanitize.sanitizeHTML("""<content><span></span><div></div></content>"""),
      """<content><span></span></content>"""

    sanitize = new Sanitize
      content: ($, $element, sanitize) =>
        sanitize.sanitizeTree $, $element,
          div: {}
          span: {}

    @assertEqual sanitize.sanitizeHTML("""<content></content>"""),
      """<content></content>"""
    @assertEqual sanitize.sanitizeHTML("""<content><div><div></div></div><span></span></content>"""),
      """<content><div></div><span></span></content>"""
    @assertEqual sanitize.sanitizeHTML("""<content><div></div><b></b><span><div></div></span></content>"""),
      """<content><div></div><span></span></content>"""
    @assertEqual sanitize.sanitizeHTML("""<content><span></span><div></div></content>"""),
      """<content><span></span><div></div></content>"""

    sanitize = new Sanitize
      content: ($, $element, sanitize) =>
        sanitize.sanitizeTree $, $element,
          div:
            attributes:
              class: true
            children:
              span: {}
              a: ($, $element, sanitize) =>
                # Allow all content.
                $element.contents()

    @assertEqual sanitize.sanitizeHTML("""<content><div class="foo"><a href=""><b></b></a><span></span></div></content>"""),
      """<content><div class="foo"><a href=""><b></b></a><span></span></div></content>"""
    @assertEqual sanitize.sanitizeHTML("""<content><div class="foo" ref="1"><a href=""><b></b></a><span ref="2"></span></div></content>"""),
      """<content><div class="foo"><a href=""><b></b></a><span></span></div></content>"""

ClassyTestCase.addTest new SanitizeTestCase()
