
    JS = 'script:not([type]), script[type="text/javascript"]'
    URL_ATTR = ['href', 'src', 'action', 'style']

    module.exports =
      EOL: require('os').EOL
      ELEMENTS: 'polymer-element:not([assetpath])'
      ABS_URL: /(^data:)|(^http[s]?:)|(^\/)/
      IMPORTS: 'link[rel="import"][href]'
      URL: /url\([^)]*\)/g
      URL_ATTR: URL_ATTR
      URL_ATTR_SEL: '[' + URL_ATTR.join('],[') + ']'
      URL_TEMPLATE: '{{.*}}'
      JS: JS
      STYLESHEET: 'link[rel="stylesheet"]'
      IMG: 'img'
      JS_SRC: JS.split(',').map( (s) -> s + '[src]').join(',')
      JS_INLINE: JS.split(',').map((s) -> s + ':not([src])').join(',')
      CSS: 'style:not([type]), style[type="text/css"]'
      POLYMER_INVOCATION: /Polymer\(([^,{]+)?(?:,\s*)?({|\))/
      POLYMER_ELEMENT: 'polymer-element'
