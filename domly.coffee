# Public Domain (-) 2011-2012 The Jsutil Authors.
# See the Jsutil UNLICENSE file for details.

define 'util', (exports, root) ->

  doc = root.document
  events = {}
  evid = 1
  isArray = Array.isArray
  lastid = 1

  propFix =
    $: "className"
    cellpadding: "cellPadding"
    cellspacing: "cellSpacing"
    class: "className"
    colspan: "colSpan"
    contenteditable: "contentEditable"
    for: "htmlFor"
    frameborder: "frameBorder"
    maxlength: "maxLength",
    readonly: "readOnly"
    rowspan: "rowSpan"
    tabindex: "tabIndex"
    usemap: "useMap"

  buildDOM = (data, parent, setID) ->
    tag = data[0] # TODO(tav): use this to check which attrs are valid.
    split = tag.split '.'
    if split.length > 1
      [tag, classes...] = split
      classes = classes.join ' '
    else
      classes = null
    split = tag.split '#'
    if split.length is 2
      [tag, id] = split
    else
      id = null
    elem = doc.createElement tag
    parent.appendChild elem
    l = data.length
    if l > 1
      attrs = data[1]
      start = 1
      if !isArray(attrs) and typeof attrs is 'object'
        for k, v of attrs
          if k.lastIndexOf('on', 0) is 0
            if typeof v isnt 'function'
              continue
            if !elem.__evi
              elem.__evi = evid++
            type = k.slice 2
            if events[elem.__evi]
              events[elem.__evi].push [type, v, false]
            else
              events[elem.__evi] = [[type, v, false]]
            elem.addEventListener type, v, false
          else
            elem[propFix[k] or k] = v
        start = 2
      for child in data[start...l]
        if typeof child is 'string'
          elem.appendChild document.createTextNode child
        else
          buildDOM child, elem
    if classes
      if elem.className.length > 0
        elem.className += " #{classes}"
      else
        elem.className = classes
    if setID
      if id
        elem.id = id
        return id
      id = elem.id
      if not id
        elem.id = id = "$#{lastid++}"
      return id
    if id
      elem.id = id
    return

  exports.domly = (data, target, retElem) ->
    frag = doc.createDocumentFragment()
    if retElem
      id = buildDOM data, frag, true
      target.appendChild frag
      return doc.getElementById id
    buildDOM data, frag, false
    target.appendChild frag
    return

  purgeDOM = (elem) ->
    evi = elem.__evi
    if evi
      for [type, func, capture] in events[evi]
        elem.removeEventListener type, func, capture
      delete events[evi]
    children = elem.childNodes
    if children
      for child in children
        purgeDOM child
    return

  exports.rmtree = (parent, elem) ->
    parent.removeChild elem
    purgeDOM elem
    return

  return
