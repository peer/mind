Initialize with:

```javascript
var sanitize = new Sanitize(allowedTags);
```

You can call then `sanitize.sanitizeHTML("<p>Your HTML string.</p>")` to get back a sanitized HTML string.

`allowedTags` is an object of tag names and allowed attributes. Allowed attributes are again an object:

```javascript
var allowedTags = {
  div: {},
  span: {
    class: true
  },
  a: function ($, $element, sanitize) {
    // Allow all content.
    return $element.contents();
  }
};
```

`span` tag can have a `class` attribute, all other attributes are removed.
As seen in the example for the `a` tag, allowed attributes can instead be also a function which should sanitize the
tag element itself and return sanitized content. Inside functions you can call any other method of the
`sanitize` object.

For example, `sanitizeTree` allows you to specify an expected tree of elements the given element's children (its
content) have to match. Syntax of the `expectedTree` argument can be seen in the following example:

```javascript
{
  figure: {
    attributes: {
      "class": true
    },
    children: [
      {
        img: {
          attributes: {
            src: true,
            width: true,
            height: true
          }
        }
      }, {
        figcaption: {
          attributes: {
            "class": true
          },
          children: {
            $text: true,
            span: {
              attributes: {
                "class": true
              },
              children: {
                $text: true
              }
            }
          }
        }
      }
    ]
  }
}
```

`attributes` list allowed attributes for a given tag. `children` contain an array of objects, or directly an object.
If it is an array, then children tags have to be exactly in the provided order. Otherwise, any number of any of tags
present in the object are valid. Special tag `$text` can be used for text nodes. Alternatively, tag definitions
can be a function instead which should sanitize the tag element itself and return sanitized content.
