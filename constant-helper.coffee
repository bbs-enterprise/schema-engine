###
  class ConstantHelper
###

class ConstantHelper

  @objectString : 'object'
  @undefinedString : 'undefined'

  ## Checks if a particular property of the "obj" parameter is null or not
  # obj = the object to whom the property belongs to
  # propertyName = name of the property to be checked for
  @isNotNull : ( obj , propertyName ) ->
    if propertyName is null || ( typeof propertyName ) is ConstantHelper.undefinedString
      if obj is null || ( typeof obj ) is ConstantHelper.undefinedString
        return false
      return true
    if obj[ propertyName ] is null || ( typeof obj[ propertyName ] ) is ConstantHelper.undefinedString
      return false
    return true

  @cloneObj : ( obj ) ->
    if not obj? or typeof obj isnt 'object'
      return obj

    if ( obj instanceof Date )
      res = ( new Date obj.getTime() )
      return res

    if ( obj instanceof RegExp )
      flags = ''
      flags += 'g' if obj.global?
      flags += 'i' if obj.ignoreCase?
      flags += 'm' if obj.multiline?
      flags += 'y' if obj.sticky?
      return new RegExp(obj.source, flags)

    newInstance = new obj.constructor()

    for key of obj
      newInstance[key] = @cloneObj obj[key]

    return newInstance

  @htmlEscape : ( stringData ) ->
    return String( stringData )
            .replace( /&/g , '&amp;' )
            .replace( /"/g , '&quot;' )
            .replace( /'/g , '&#39;' )
            .replace( /</g , '&lt;' )
            .replace( />/g , '&gt;' )

  @htmlUnescape : ( stringData ) ->
    return String( stringData )
        .replace( /&quot;/g , '"' )
        .replace( /&#39;/g , "'" )
        .replace( /&lt;/g , '<' )
        .replace( /&gt;/g , '>' )
        .replace( /&amp;/g , '&' )

  @onlyContainsDigits : ( stringData ) ->
    len = stringData.length
    res = true
    for i in [ 0 .. len - 1 ]
      if ! ( stringData.charCodeAt( i ) >= '0'.charCodeAt( 0 ) && stringData.charCodeAt( i ) <= '9'.charCodeAt( 0 ) )
        return false
    return true

@ConstantHelper = ConstantHelper
