objectify = (node) ->
  len = node.attributes.length

  attrs = {}
  for i in [0...len]
    attr = node.attributes[i]
    attrs[attr.name] = attr.value

  # Returned object:
  tag: node.tagName
  attr: attrs # attributes
  style: getComputedStyle(node).cssText # computed style

window.DomSerializer =
  toObject: (root) ->
    objectify root


  toDom: (str) ->
