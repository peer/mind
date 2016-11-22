class BalanceText extends UIComponent
  @register 'BalanceText'

  constructor: (styleClassesArrays...) ->
    # Removing kwargs.
    styleClassesArrays.pop() if styleClassesArrays[styleClassesArrays.length - 1] instanceof Spacebars.kw

    styleClasses = _.filter _.flatten(styleClassesArrays), (item) =>
      _.isString item

    styleClasses.push 'balance-text'

    styleClasses = _.uniq styleClasses

    @classes = styleClasses.join ' '

  content: ->
    Tracker.afterFlush =>
      # This method has a side-effect, not nice, but the easiest to make sure we
      # balance text after the content has been (re)rendered.
      $.fn.balanceTextUpdate()

    # It is important that content is wrapped inside a div because then Blaze easily removes this div even if inside
    # text has been modified by balance text library. This is still reactive and all HTML is properly escaped, just
    # that it is rendered (and replaced) all at once. This addresses the issue that Blaze cannot properly update
    # content which has been modified by balance text library because the latter changes text elements Blaze
    # uses to know where to update.
    """<div class="#{@classes}">#{Blaze.toHTML(@_componentInternals.templateInstance().view.templateContentBlock)}</div>"""
