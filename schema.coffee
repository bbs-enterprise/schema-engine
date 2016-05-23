###
  class Schema
###

{ ConstantHelper } = require './constant-helper'
{ TopoSort } = require './topological-sort'

class Schema
  self : {}

  ## Constructor for Schema class. If some of the required properties are not set in the jsonSignature parameter, it'll be set here.
  # jsonSignature = the signature/model definition of the data
  # options = an object containing common options
  #   suppressCyclicDataErrors: true/false [default:true]
  #   ignoreUnidentifiedData: true/false (if false, throws error when unidentified data is encountered during isValid call) [default:true]
  constructor : ( jsonSignature = {}, options = {} ) ->
    if( ConstantHelper.isNotNull options , 'suppressCyclicDataErrors' ) is false
      options.suppressCyclicDataErrors = false
    if( ConstantHelper.isNotNull options , 'ignoreUnidentifiedData' ) is false
      options.ignoreUnidentifiedData = false
    if( ConstantHelper.isNotNull options , 'alwaysEscapeHtml' ) is false
      options.alwaysEscapeHtml = false

    jsonSignature = @_checkForRequiredPropertiesRecursively jsonSignature

    @schemaOptions = options
    @schemaJsonSignature = jsonSignature

    @_calculateMapOrderedKeyList jsonSignature

    @topoSortObj = new TopoSort()
    @topoSortObj.passSchemaJsonSignature @schemaJsonSignature
    @orderedPropertyListWithPath = @topoSortObj.runTopologicalSort()

    return null

  ## Calculates the ordered map key list for each property. This property orders key list based on their 'compute'
  ## function requirements. All the sibling of a property that do not have a 'compute' property, is validated before
  ## compute function is called.
  # jsonSignature = the signature/model definition of the validation object
  _calculateMapOrderedKeyList : ( jsonSignature ) =>
    if ( ConstantHelper.isNotNull jsonSignature , 'map' ) is true
      jsonSignature.__mapOrderedKeyList = []

      if ( ConstantHelper.isNotNull jsonSignature , 'customEvaluationOrder' ) is true
        jsonSignature.__mapOrderedKeyList = jsonSignature.customEvaluationOrder

      for childProperty , childValue of jsonSignature.map
        if childProperty in jsonSignature.__mapOrderedKeyList
          continue

        if 'compute' of childValue
          jsonSignature.__mapOrderedKeyList.push childProperty
        else
          jsonSignature.__mapOrderedKeyList.unshift childProperty

      for childProperty , childValue of jsonSignature.map
        @_calculateMapOrderedKeyList childValue

  ## Checks for appropriate values in "jsonSignature" validation object keys
  # jsonSignature = the signature/model definition of the validation object
  _checkForRequiredValidationPropertiesRecursively : ( jsonSignature ) =>
    for key , value of jsonSignature
      if key is 'OR'
        if ( ConstantHelper.isNotNull value ) is false
          jsonSignature[ key ] = []
        else
          res = []
          for item in jsonSignature[ key ]
            res.push ( @_checkForRequiredValidationPropertiesRecursively item )
          jsonSignature[ key ] = res

      if key is 'AND'
        if ( ConstantHelper.isNotNull value ) is false
          jsonSignature[ key ] = []
        else
          res = []
          for item in jsonSignature[ key ]
            res.push ( @_checkForRequiredValidationPropertiesRecursively item )
          jsonSignature[ key ] = res

      if key is 'NOT'
        if ( ConstantHelper.isNotNull value ) is false
          jsonSignature[ key ] = {}

      if key is 'custom'
        #if ( ConstantHelper.isNotNull jsonSignature[ key ] , 'message' ) is false
          #jsonSignature[ key ][ 'message' ] = 'No message is defined for custom property. Custom function returned false.'

        if ( ConstantHelper.isNotNull jsonSignature[ key ] , 'fn' ) is false
          err = new Error
          err.errorDetails = 'No function defined for custom validation property.'
          throw err

        if ( ConstantHelper.isNotNull jsonSignature[ key ] , 'params' ) is false
          err = new Error
          err.errorDetails = 'No params defined for custom validation property.'
          throw err

    return jsonSignature

  ## Checks for validation property existance outside of validation object. If found, places those properties inside the validation object.
  # jsonSignature = the signature/model definition of the schema
  _checkForValidationPropertiesOutsideOfValidationObject : ( jsonSignature ) =>
    validationKeywords = [ 'minLength' , 'maxLength' , 'OR' , 'NOT' , 'AND' , 'message' ]
    res = {}

    for key , value of jsonSignature
      if key in validationKeywords
        if( ConstantHelper.isNotNull jsonSignature.validation , 'AND' ) is false
          val = jsonSignature.validation
          jsonSignature.validation = {}
          jsonSignature.validation.AND = []
          if( JSON.stringify val ) != '{}'
            jsonSignature.validation.AND.push val

        obj = {}
        obj[ key ] = value
        jsonSignature.validation.AND.push obj

      else
        res[ key ] = value
    res.validation = jsonSignature.validation

    return res

  ## Checks for required properties for jsonSignature object. Assigns default values if does not exist. Only meant to be called from schema class constructor.
  # jsonSignature = the signature/model definition of the schema
  _checkForRequiredPropertiesRecursively : ( jsonSignature ) =>
    if( ConstantHelper.isNotNull jsonSignature , 'allowNull' ) is false
      jsonSignature.allowNull = true
    if( ConstantHelper.isNotNull jsonSignature , 'validation' ) is false
      jsonSignature.validation = {}
    jsonSignature.validation = @_checkForRequiredValidationPropertiesRecursively jsonSignature.validation
    jsonSignature = @_checkForValidationPropertiesOutsideOfValidationObject jsonSignature
    if( ConstantHelper.isNotNull jsonSignature , 'type' ) is false
      jsonSignature.type = ConstantHelper.objectString
    if jsonSignature.type is ConstantHelper.objectString && ( jsonSignature.map is null || ( typeof jsonSignature.map ) is ConstantHelper.undefinedString )
      jsonSignature.map = {}
    if jsonSignature.type is 'literal'
      if ( ConstantHelper.isNotNull jsonSignature , 'minLength' ) is false
        jsonSignature.minLength = 0
      if ( ConstantHelper.isNotNull jsonSignature , 'maxLength' ) is false
        jsonSignature.maxLength = Number.POSITIVE_INFINITY

    if jsonSignature.type is 'number'
      if ( ConstantHelper.isNotNull jsonSignature , 'minLength' ) is false
        jsonSignature.minLength = Number.NEGATIVE_INFINITY
      if ( ConstantHelper.isNotNull jsonSignature , 'maxLength' ) is false
        jsonSignature.maxLength = Number.POSITIVE_INFINITY

    for key , value of jsonSignature.map
      jsonSignature.map[ key ] = @_checkForRequiredPropertiesRecursively value
    return jsonSignature

  ## Returns true if property value of provided propertyName, that is 'dataString' parameter, statisfies minimum length and maximum length
  ## minimum length can be empty/null and so can be maximum length, works as a 'OR' check between minimum and maximum length
  # propertyName = the name of the property whose value is used here for validation
  # dataString = the string value of propertyName, can be null
  # minLength = minimum allowable length of dataString, can be null
  # maxLength = maximum allowable length of dataString, can be null
  _isOfValidLength : ( propertyName , dataString , minLength , maxLength ) ->
    if ( typeof dataString ) is 'number'
      dataString = '' + dataString
    error = new Error

    if dataString is null
      error.errorDetails = 'null value supplied in "dataString" parameter for "_isOfValidLength" method'
      throw error
    if minLength != null && ( typeof minLength ) is 'number' && dataString.length < minLength
      error.errorDetails = 'Minimum length not satisfied of ' + propertyName + '. Expected length of at least ' + minLength + ' and received a length of ' + dataString.length
      throw error
    if minLength != null && ( typeof maxLength ) is 'number' && dataString.length > maxLength
      error.errorDetails = 'Maximum length not satisfied of ' + propertyName + '. Expected length of at most ' + maxLength + ' and received a length of ' + dataString.length
      throw error
    return true

  ## Returns true if the supplied emailAddress statisfies the regex test
  ## otherwise returns false
  # emailAddress = a string value containing email address
  _isValidEmail : ( emailAddress ) ->
    emailRegex = /^([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$/i
    return emailRegex.test emailAddress

  ## Returns true if the suppliedObject complies to the signature
  ## returns false if suppliedObject does not comply to the signature
  # suppliedObject = a js value (can be an object, a standalone string etc..)
  isValid : ( suppliedObject ) =>
    try
      @extract suppliedObject
      return true
    catch ex
      return false

  ## Checks for validation of "literal" type i.e. minLength and maxLength.
  # validationObj = validation schema object
  # value = actual value supplied from calle
  # key = property name upon which the following validation is operated
  _checkForValidationOfLiteralType : ( validationObj , value , key ) ->
    returnObj = {}
    returnObj.res = []
    returnObj.errorDetails = []

    if ( ConstantHelper.isNotNull value ) is false
      return returnObj
    if( ( ConstantHelper.isNotNull validationObj , 'minLength' ) is true || ( ConstantHelper.isNotNull validationObj , 'maxLength' ) is true )
      try
        @_isOfValidLength key , '' + value , validationObj.minLength , validationObj.maxLength
      catch ex
        returnObj.errorDetails.push { message : ex.errorDetails , code : 'ERR_UNDECIDED' , origin : 'system' }
        returnObj.res.push false

    return returnObj

  ## Checks for validation of "string" type i.e. email validation and other string related operations.
  # validationObj = validation schema object
  # value = actual value supplied from calle
  # key = property name upon which the following validation is operated
  _checkForValidationOfStringType : ( validationObj , value , key , schemaObjectType ) ->
    returnObj = {}
    returnObj.res = []
    returnObj.errorDetails = []

    if ( ( ConstantHelper.isNotNull validationObj , 'validateAs' ) is true && validationObj.validateAs is 'email' )
      if @_isValidEmail( value ) is false
        returnObj.errorDetails.push { message : 'Email not in valid format.' , code : 'ERR_UNDECIDED' , origin : 'validation' }
        returnObj.res.push false
      else
        returnObj.res.push true

    if ( ConstantHelper.isNotNull validationObj , 'matchesExactly' ) is true
      if value != validationObj.matchesExactly
        returnObj.errorDetails.push { message : 'Supplied string value doesn\'t match with expected string "' + validationObj.matchesExactly + '".' , code : 'ERR_UNDECIDED' , origin : 'system' }

    if ( ConstantHelper.isNotNull validationObj , 'startsWith' ) is true
      if value.indexOf validationObj.startsWith != 0
        returnObj.errorDetails.push { message : 'Supplied string value doesn\'t start with expected string "' + validationObj.startsWith + '".' , code : 'ERR_UNDECIDED' , origin : 'system' }

    if ( ConstantHelper.isNotNull validationObj , 'endsWith' ) is true
      if value.indexOf validationObj.endsWith != ( value.length - validationObj.endsWith.length )
        returnObj.errorDetails.push { message : 'Supplied string value doesn\'t end with expected string "' + validationObj.endsWith + '".' , code : 'ERR_UNDECIDED' , origin : 'system' }

    if ( ConstantHelper.isNotNull validationObj , 'contains' ) is true
      if ( typeof validationObj.contains ) is 'string'
        validationObj.contains = [ validationObj.contains ]
      for itemString in validationObj.contains
        if ( value.indexOf itemString ) is -1
          returnObj.errorDetails.push { message : 'Supplied string value doesn\'t contain expected string "' + itemString + '".' , code : 'ERR_UNDECIDED' , origin : 'system' }
          returnObj.res.push false
        else
          returnObj.res.push true

    if ( ConstantHelper.isNotNull validationObj , 'doesNotContain' ) is true
      for itemString in validationObj.doesNotContain
        if value.indexOf itemString != -1
          returnObj.errorDetails.push { message : 'Supplied string value contains unexpected string "' + itemString + '".' , code : 'ERR_UNDECIDED' , origin : 'system' }

    return returnObj

  ## Calculates the appropriate property value from global supplied object and provided parentList. Constructs
  ## the whole path from 'ROOT_OBJECT' to the designated property.
  # parameterList = list of parameters that is used in either from custom validations or 'compute' property
  # currentValue = value of the current property
  # parentList = list of parents up until the current property
  _calculatePropertyValueFromParamList : ( parameterList , currentValue , parentList , arrayIndexUsage ) ->
    paramValues = []
    for singleParameter in parameterList
      if singleParameter is '.'
        paramValues.push currentValue
        continue

      computeParentList = singleParameter.split '^'
      numberOfParents = computeParentList.length - 1
      computeChildList = computeParentList[ computeParentList.length - 1 ].split '.'
      requiredParentList = parentList.slice 0 , ( parentList.length - numberOfParents )
      if ( computeChildList.length is 1 and computeChildList[ 0 ] is '' )
        wholePathFromRoot = requiredParentList
      else
        wholePathFromRoot = requiredParentList.concat computeChildList
      obj = ConstantHelper.cloneObj @globalRes
      for childPropertyName in wholePathFromRoot
        if childPropertyName is 'ARRAY-ITEM'
          continue
        obj = obj[ childPropertyName ]
        for item in arrayIndexUsage
          if item.property is childPropertyName
            obj = obj[ item.index ]

      paramValues.push obj
    return paramValues

  _calculatePropertyValueFromPathList : ( pathList ) ->
    pathList = pathList.slice 1 , pathList.length
    obj = ConstantHelper.cloneObj @globalSuppliedObject
    if pathList.length is 0
      return obj

    for pathItem in pathList
      if pathItem is 'ARRAY-ITEM'
        continue
      obj = obj[ pathItem ]

    return obj

  _setValueToProperty : ( pathList , val , res , isArray ) ->
    if pathList.length is 0
      res = val
      return val

    pathItem = pathList[ 0 ]
    newPathList = pathList.slice 1 , pathList.length

    if pathItem is 'ARRAY-ITEM'
      res = []
      res[ pathItem ] = @_setValueToProperty newPathList , val , res , true

    else if isArray is true
      fl = 0
      obj = res
      i = 0
      while i < pathItem
        obj.push {}
        i++
      res[ pathItem ] = @_setValueToProperty newPathList , val , obj[ pathItem ] , false

    else
      if ( ConstantHelper.isNotNull res , pathItem ) is false
        res[ pathItem ] = {}
      res[ pathItem ] = @_setValueToProperty newPathList , val , res[ pathItem ] , false

    return res

  _calculatePropertySignatureFromPathList : ( pathList , jsonSignature ) ->
    pathList = pathList.slice 1 , pathList.length

    if ( pathList.length is 0 )
      return jsonSignature

    if ( jsonSignature.type is 'object' )
      if ( ConstantHelper.isNotNull jsonSignature.map , pathList[ 0 ] ) is false
        error = new Error
        error.errorDetails = 'No json signature map found for ' + pathList[ 0 ] + ' property.'
        throw error

      newPathList = pathList.slice 1 , pathList.length
      return ( @_calculatePropertySignatureFromPathList newPathList , jsonSignature.map[ pathList[ 0 ] ] )
    else if ( jsonSignature.type is 'array' )
      if ( ConstantHelper.isNotNull jsonSignature.def , pathList[ 0 ] ) is false
        error = new Error
        error.errorDetails = 'No json signature map found for ' + pathList[ 0 ] + ' property.'
        throw error

      newPathList = pathList.slice 1 , pathList.length
      return ( @_calculatePropertySignatureFromPathList newPathList , jsonSignature.def[ pathList[ 0 ] ] )

    error = new Error
    error.errorDetails = 'Invalid path list found in \'_calculatePropertySignatureFromPathList\' method. Path list wanted to go beyond the primitive data type in json signature.'
    throw error

  ## Performs complex schema validations.
  # validationObj = schema validation object
  # value = actual value that is supplied
  # key = property name that holds the value
  # schemaObjectType = appropriate schema json signature object
  _checkForValidation : ( validationObj , value , key , schemaObjectType , parentList , arrayIndexUsage ) =>
    if( ConstantHelper.isNotNull validationObj , 'message' ) is true
      errorMessage = validationObj.message
    else
      errorMessage = ''

    returnObj = {}
    returnObj.res = []
    returnObj.errorDetails = []

    for propertyName , propertyValue of validationObj

      if propertyName is 'AND'
        andResult = true
        tempErrorDetails = []
        for item in propertyValue
          r1 = @_checkForValidation item , value , key , schemaObjectType , parentList , arrayIndexUsage
          curResult = true
          for arrayItem in r1.res
            andResult &= arrayItem
            curResult &= arrayItem
          if curResult is false or curResult is 0
            tempErrorDetails = tempErrorDetails.concat r1.errorDetails
        if andResult is 0 || andResult is false
          andResult = false
        else
          andResult = true
        if andResult is false
          returnObj.errorDetails = returnObj.errorDetails.concat tempErrorDetails
        returnObj.res.push andResult

      else if propertyName is 'OR'
        orResult = false
        tempErrorDetails = []
        for item in propertyValue
          r1 = @_checkForValidation item , value , key , schemaObjectType , parentList , arrayIndexUsage
          curResult = false
          for arrayItem in r1.res
            orResult |= arrayItem
            curResult |= arrayItem
          if curResult is false or curResult is 0
            tempErrorDetails = tempErrorDetails.concat r1.errorDetails
          if orResult is 0 || orResult is false
            orResult = false
          else
            orResult = true
        if orResult is false
          returnObj.errorDetails = returnObj.errorDetails.concat tempErrorDetails
        returnObj.res.push orResult

      else if propertyName is 'NOT'
        property = null
        tempErrorDetails = []
        notResult = true

        if( ConstantHelper.isNotNull propertyValue , 'OR' ) is true
          notResult = false
          property = propertyValue.OR
        else if( ConstantHelper.isNotNull propertyValue , 'AND' ) is true
          notResult = true
          property = propertyValue.AND

        if property != null
          for item in property
            r1 = @_checkForValidation item , value , key , schemaObjectType , parentList , arrayIndexUsage
            if( ConstantHelper.isNotNull propertyValue , 'OR' ) is true
              curResult = false
            else if( ConstantHelper.isNotNull propertyValue , 'AND' ) is true
              curResult = true
            for arrayItem in r1.res
              if( ConstantHelper.isNotNull propertyValue , 'OR' ) is true
                notResult |= arrayItem
                curResult |= arrayItem
              else if( ConstantHelper.isNotNull propertyValue , 'AND' ) is true
                notResult &= arrayItem
                curResult &= arrayItem
            if notResult is false or notResult is 0
              notResult = false
            else
              notResult = true
            if curResult is false or curResult is 0
              tempErrorDetails = tempErrorDetails.concat r1.errorDetails
          notResult = ! notResult
          if notResult is 0 || notResult is false
            notResult = false
          else
            notResult = true
        if notResult is false
          returnObj.errorDetails = returnObj.errorDetails.concat tempErrorDetails
        returnObj.res.push notResult

      else if propertyName is 'custom'
        customMessage = propertyValue.message
        paramValues = @_calculatePropertyValueFromParamList propertyValue.params , value , parentList , arrayIndexUsage

        try
          customFunctionResult = propertyValue.fn.apply {} , paramValues
          if ! ( customFunctionResult is true || customFunctionResult is false )
            err = new Error
            err.errorDetails = 'Unrecognized value returned from custom validator function of "' + key + '" property. Expected the value to be boolean.'
            throw err
            #TO-DO future use-case may require to suppress this exception
        catch ex
          customFunctionResult = false
          if ( ConstantHelper.isNotNull ex , 'customErrorMessage' ) is true
            returnObj.errorDetails.push { message : ex.customErrorMessage , code : 'ERR_UNDECIDED' , origin : 'custom-fn' }
          if ( ConstantHelper.isNotNull ex , 'errorDetails' ) is true
            returnObj.errorDetails.push { message : 'Error thrown from custom validator function of "' + key + '" property.' , code : 'ERR_UNDECIDED' , origin : 'system' }
            returnObj.errorDetails.push { message : ex.errorDetails , code : 'ERR_UNDECIDED' , origin : 'system' }

        returnObj.res.push customFunctionResult
        if customFunctionResult is false
          if ( ConstantHelper.isNotNull customMessage ) is true
            returnObj.errorDetails.push { message : customMessage , code : 'ERR_UNDECIDED' , origin : 'user' }

      else
        if schemaObjectType is 'literal' || schemaObjectType is 'string' || schemaObjectType is 'number' || schemaObjectType is 'float' || schemaObjectType is 'integer'
          r1 = @_checkForValidationOfLiteralType validationObj , value , key
          returnObj.res = returnObj.res.concat r1.res
          returnObj.errorDetails = returnObj.errorDetails.concat r1.errorDetails

        if schemaObjectType is 'string'
          r1 = @_checkForValidationOfStringType validationObj , value , key
          returnObj.res = returnObj.res.concat r1.res
          returnObj.errorDetails = returnObj.errorDetails.concat r1.errorDetails

    return returnObj

  ## Creates a new entry in errorDetails with the new errorMessage
  # errorDetails = the actual errorDetails object
  # propertyName = name of the property for which this particular error has occured
  # errorMessage = error message thrown from calle
  _updateErrorDetailsObject : ( errorDetails , errorDetailsMessagesPath , parentList , propertyName , errorMessageList ) ->
    if errorMessageList.length is 0
      return errorDetails

    parentListCopy = ( item for item in parentList )
    newParentList = parentListCopy.slice 1 , parentListCopy.length
    parentItem = parentList[ 0 ]

    errorMessagePathItem = errorDetailsMessagesPath[ 0 ]
    newErrorDetailsMessagesPath = errorDetailsMessagesPath.slice 1 , errorDetailsMessagesPath.length
    if( errorMessagePathItem is propertyName )
      if ( ConstantHelper.isNotNull errorDetails , errorMessagePathItem ) is false
        errorDetails[ errorMessagePathItem ] = []
      newErrorMessageList = errorDetails[ errorMessagePathItem ]
      if ( Array.isArray newErrorMessageList ) is false
        newErrorMessageList = []
      for item in errorMessageList
        if ( item in newErrorMessageList ) is false
          if( ConstantHelper.isNotNull newErrorMessageList ) is false
            newErrorMessageList = []
          newErrorMessageList.push item
      errorDetails[ errorMessagePathItem ] = newErrorMessageList
      return errorDetails

    if errorMessagePathItem is 'ARRAY-ITEM'
      if ( ConstantHelper.isNotNull errorDetails ) is false || ( Array.isArray errorDetails ) is false
        errorDetails = []
      obj = errorDetails
      errorDetails = @_updateErrorDetailsObject obj , newErrorDetailsMessagesPath , newParentList , propertyName , errorMessageList

    else if ( typeof errorMessagePathItem ) is 'number'
      sz = errorDetails.length
      if errorMessagePathItem >= sz
        newSz = errorMessagePathItem + 1 - sz
        for i in [ 0 .. newSz - 1 ]
          errorDetails.push {}
      obj = errorDetails[ errorMessagePathItem ]
      errorDetails[ errorMessagePathItem ] = @_updateErrorDetailsObject obj , newErrorDetailsMessagesPath , newParentList , propertyName , errorMessageList

    else
      if ( ConstantHelper.isNotNull errorDetails , errorMessagePathItem ) is false
        errorDetails[ errorMessagePathItem ] = {}
      obj = errorDetails[ errorMessagePathItem ]
      errorDetails[ errorMessagePathItem ] = @_updateErrorDetailsObject obj , newErrorDetailsMessagesPath , newParentList , propertyName , errorMessageList

    return errorDetails

  ## Checks if a particular property of the "obj" parameter is null or not
  # obj = the object to whom the property belongs to
  # propertyName = name of the property to be checked for
  isNotNull : ( obj , propertyName ) ->
    # if ‘myKey’ of myObj and typeof myObj.myKey isnt ‘undefined’ and myObj isnt null
    if propertyName is null || ( typeof propertyName ) is ConstantHelper.undefinedString
      if obj is null || ( typeof obj ) is ConstantHelper.undefinedString
        return false
      return true
    if obj[ propertyName ] is null || ( typeof obj[ propertyName ] ) is ConstantHelper.undefinedString
      return false
    return true

  ## Returns a new js object with only the part that complies to the jsonSignature if the suppliedObject complies
  ## to the signature throws meaningful error with *ALL THE VALIDATION ERRORS* if suppliedObject does not comply to the signature
  # suppliedObject = a js value (can be an object, a standalone string etc..)
  _extractMethodExecution : ( suppliedObject , propertyName = 'ROOT_OBJECT' , schemaJsonSignatureParameter = @schemaJsonSignature , parentList = [] , errorDetails = { 'ROOT_OBJECT' : {} } , resObj , originalSuppliedObject , arrayIndexUsage , errorDetailsMessagesPath ) =>
    res = {}

    allowedObjectTypes = [ 'literal' , 'string' , 'number' , 'integer' , 'float' , 'boolean' , 'object' , 'array' , 'schema' , 'ARRAY-ITEM' ]

    if propertyName is 'ARRAY-ITEM'
      suppliedObjectType = propertyName
    else
      suppliedObjectType = schemaJsonSignatureParameter.type

    newParentList = ( item for item in parentList )

    if suppliedObjectType in [ 'object' , 'array' , 'schema' ]
      suppliedObject = resObj

    if ( ConstantHelper.isNotNull suppliedObject ) is false
      suppliedObject = null

    # Compute the value ahead of all the validations
    if ( ConstantHelper.isNotNull schemaJsonSignatureParameter.compute )
      computeParameters = @_calculatePropertyValueFromParamList schemaJsonSignatureParameter.compute.params , suppliedObject , newParentList , arrayIndexUsage
      computedObject = schemaJsonSignatureParameter.compute.fn.apply {} , computeParameters
      suppliedObject = computedObject

    # Common checks like allowNull, validation, type etc
    if schemaJsonSignatureParameter.allowNull is false && ( ConstantHelper.isNotNull suppliedObject ) is false
      @_updateErrorDetailsObject errorDetails , errorDetailsMessagesPath , newParentList , propertyName , [ { message : 'Required.' , code : 'ERR_INPUT_REQUIRED' , origin : 'required' } ]
      @_updateErrorDetailsObject errorDetails , errorDetailsMessagesPath , newParentList , propertyName , [ { message : 'null value is not applicable for ' + propertyName + ' property.' , code : 'ERR_NULL_NOT_ALLOWED' , origin : 'system' } ]

    if schemaJsonSignatureParameter.allowNull is true
      if ( ConstantHelper.isNotNull schemaJsonSignatureParameter , 'validation' ) is true && ( JSON.stringify schemaJsonSignatureParameter.validation ) != '{}'
        newSuppliedObject = suppliedObject
        if ( ConstantHelper.isNotNull originalSuppliedObject ) is false
          newSuppliedObject = null
        validationResult = @_checkForValidation schemaJsonSignatureParameter.validation , newSuppliedObject , propertyName , suppliedObjectType , newParentList , arrayIndexUsage
        customErrorMessage = 'Validation error in "' + propertyName + '" property (custom error message not provided in schema signature).'
        for item in validationResult.res
          if item is false
            if ( ConstantHelper.isNotNull schemaJsonSignatureParameter.validation , 'message' ) is true
              customErrorMessage = schemaJsonSignatureParameter.validation.message
              validationResult.errorDetails.push { message : customErrorMessage , code : 'ERR_UNDECIDED' , origin : 'user' }
            else
              validationResult.errorDetails.push { message : customErrorMessage , code : 'ERR_UNDECIDED' , origin : 'system' }
            @_updateErrorDetailsObject errorDetails , errorDetailsMessagesPath , newParentList , propertyName , validationResult.errorDetails
            break

    if suppliedObjectType not in allowedObjectTypes
      @_updateErrorDetailsObject errorDetails , errorDetailsMessagesPath , newParentList , propertyName , [ { message : '"type" property value is not recognized for ' + propertyName + ' property.' , code : 'ERR_UNDECIDED' , origin : 'system' } ]

    if suppliedObjectType isnt 'ARRAY-ITEM' && ( ConstantHelper.isNotNull schemaJsonSignatureParameter , 'type' ) is false
      @_updateErrorDetailsObject errorDetails , errorDetailsMessagesPath , newParentList , propertyName , [ { message : '"type" property is not set for "' + propertyName + '".' , code : 'ERR_UNDECIDED' , origin : 'system' } ]

    if schemaJsonSignatureParameter.allowNull is true && ( ConstantHelper.isNotNull suppliedObject ) is false
      return null

    # Run the validation against the validation property
    if ( ConstantHelper.isNotNull schemaJsonSignatureParameter , 'validation' ) is true && ( ConstantHelper.isNotNull suppliedObject ) is true && ( ConstantHelper.isNotNull originalSuppliedObject ) is true && ( JSON.stringify schemaJsonSignatureParameter.validation ) != '{}'
      validationResult = @_checkForValidation schemaJsonSignatureParameter.validation , suppliedObject , propertyName , suppliedObjectType , newParentList , arrayIndexUsage
      customErrorMessage = 'Validation error in "' + propertyName + '" property (custom error message not provided in schema signature).'
      for item in validationResult.res
        if item is false
          if ( ConstantHelper.isNotNull schemaJsonSignatureParameter.validation , 'message' ) is true
            customErrorMessage = schemaJsonSignatureParameter.validation.message
            validationResult.errorDetails.push { message : customErrorMessage , code : 'ERR_UNDECIDED' , origin : 'user' }
          else
            validationResult.errorDetails.push { message : customErrorMessage , code : 'ERR_UNDECIDED' , origin : 'system' }
          @_updateErrorDetailsObject errorDetails , errorDetailsMessagesPath , newParentList , propertyName , validationResult.errorDetails
          break

    # Initial value assignment for all object types
    res = suppliedObject

    if suppliedObjectType is 'literal'
      validationResult = @_checkForValidationOfLiteralType schemaJsonSignatureParameter , suppliedObject , propertyName
      @_updateErrorDetailsObject errorDetails , errorDetailsMessagesPath , newParentList , propertyName , validationResult.errorDetails

    if suppliedObjectType is 'string'
      if ( typeof suppliedObject ) isnt 'string'
        @_updateErrorDetailsObject errorDetails , errorDetailsMessagesPath , newParentList , propertyName , [ { message : 'The data type of \'' + propertyName + '\' property is expected to be \'string\' but found \'' + ( typeof suppliedObject ) + '\'.' , code : 'ERR_UNDECIDED' , origin : 'system' } ]

      escapeFlag = false
      if @schemaOptions.alwaysEscapeHtml is true
        if ( ConstantHelper.isNotNull schemaJsonSignatureParameter , 'escapeHtml' ) is true
          if schemaJsonSignatureParameter.escapeHtml is true
            escapeFlag = true
        else
          escapeFlag = true
      else
        if ( ConstantHelper.isNotNull schemaJsonSignatureParameter , 'escapeHtml' ) is true
          if schemaJsonSignatureParameter.escapeHtml is true
            escapeFlag = true
      if escapeFlag is true
        suppliedObject = ConstantHelper.htmlEscape suppliedObject
        res = suppliedObject

      validationResult = @_checkForValidationOfStringType schemaJsonSignatureParameter , suppliedObject , propertyName
      @_updateErrorDetailsObject errorDetails , errorDetailsMessagesPath , newParentList , propertyName , validationResult.errorDetails

    if suppliedObjectType is 'number' || suppliedObjectType is 'float'

      if ( ConstantHelper.isNotNull schemaJsonSignatureParameter , 'tryToCoerce' )
        if schemaJsonSignatureParameter.tryToCoerce is true
          if( typeof suppliedObject ) is 'string'
            res = parseFloat suppliedObject
            if ( isNaN res ) is true || ( ConstantHelper.onlyContainsDigits suppliedObject ) is false
              @_updateErrorDetailsObject errorDetails , errorDetailsMessagesPath , newParentList , propertyName , [ { message : 'The supplied value of ' + propertyName + ' is not a number, it is expected to be a number.' , code : 'ERR_UNDECIDED' , origin : 'system' } ]

    if suppliedObjectType is 'integer'
      if ( ConstantHelper.isNotNull schemaJsonSignatureParameter , 'tryToCoerce' )
        if schemaJsonSignatureParameter.tryToCoerce is true
          if( typeof suppliedObject ) is 'string'
            res = parseInt suppliedObject
            if ( isNaN res ) is true || ( ConstantHelper.onlyContainsDigits suppliedObject ) is false
              @_updateErrorDetailsObject errorDetails , errorDetailsMessagesPath , newParentList , propertyName , [ { message : 'The supplied value of ' + propertyName + ' is not an integer, it is expected to be an integer.' , code : 'ERR_UNDECIDED' , origin : 'system' } ]
        else if ( ( typeof suppliedObject ) != 'number' || ( ( '' + suppliedObject ).indexOf '.' ) != -1 )
          @_updateErrorDetailsObject errorDetails , errorDetailsMessagesPath , newParentList , propertyName , [ { message : 'The supplied value of ' + propertyName + ' is not an integer, it is expected to be an integer.' , code : 'ERR_UNDECIDED' , origin : 'system' } ]
      else if ( ( typeof suppliedObject ) != 'number' || ( ( '' + suppliedObject ).indexOf '.' ) != -1 )
        @_updateErrorDetailsObject errorDetails , errorDetailsMessagesPath , newParentList , propertyName , [ { message : 'The supplied value of ' + propertyName + ' is not an integer, it is expected to be an integer.' , code : 'ERR_UNDECIDED' , origin : 'system' } ]

    if suppliedObjectType is 'float'

      if ( ConstantHelper.isNotNull schemaJsonSignatureParameter , 'maxPrecision' )
        if ( ConstantHelper.isNotNull schemaJsonSignatureParameter , 'roundingStrategy' )
          if schemaJsonSignatureParameter.roundingStrategy is 'ceil'
            res = suppliedObject.toFixed schemaJsonSignatureParameter.maxPrecision + 1
            res = '' + res
            res = res.substr 0 , res.length - 1
            res += '9'
            res = parseFloat res
            if ( isNaN res ) is true || ( ConstantHelper.onlyContainsDigits suppliedObject ) is false
              @_updateErrorDetailsObject errorDetails , errorDetailsMessagesPath , newParentList , propertyName , [ { message : 'The supplied value of ' + propertyName + ' is not a float, it is expected to be a float.' , code : 'ERR_UNDECIDED' , origin : 'system' } ]
            res = suppliedObject.toFixed schemaJsonSignatureParameter.maxPrecision

          if schemaJsonSignatureParameter.roundingStrategy is 'floor'
            res = suppliedObject.toFixed schemaJsonSignatureParameter.maxPrecision + 1
            res = '' + res
            res = res.substr 0 , res.length - 1
            res = parseFloat res
            if ( isNaN res ) is true || ( ConstantHelper.onlyContainsDigits suppliedObject ) is false
              @_updateErrorDetailsObject errorDetails , errorDetailsMessagesPath , newParentList , propertyName , [ { message : 'The supplied value of ' + propertyName + ' is not a float, it is expected to be a float.' , code : 'ERR_UNDECIDED' , origin : 'system' } ]

          if schemaJsonSignatureParameter.roundingStrategy is 'approximate'
            res = suppliedObject.toFixed schemaJsonSignatureParameter.maxPrecision

    if suppliedObjectType is 'boolean'
      if ( typeof suppliedObject ) != 'boolean'
        @_updateErrorDetailsObject errorDetails , errorDetailsMessagesPath , newParentList , propertyName , [ { message : 'Expected "boolean" values and received ' + ( typeof suppliedObject ) , code : 'ERR_UNDECIDED' , origin : 'system' } ]

    # Apply the mutation function here and assign the resultant value to the 'suppliedObject' property
    if suppliedObjectType in [ 'literal' , 'string' , 'number' , 'integer' , 'float' , 'boolean' ]
      if ( ConstantHelper.isNotNull schemaJsonSignatureParameter , 'mutationFn' )
        res = schemaJsonSignatureParameter.mutationFn.apply {} , [ suppliedObject ]
        suppliedObject = res

    return res

  _sortErrorMessageListBasedOnPriority : ( errorDetailsObject ) ->
    if ( typeof errorDetailsObject ) == 'object' && ( Array.isArray errorDetailsObject ) is true
      if ( ConstantHelper.isNotNull errorDetailsObject[ 0 ] , 'message' ) is true and ( ConstantHelper.isNotNull errorDetailsObject[ 0 ] , 'code' ) is true and ( ConstantHelper.isNotNull errorDetailsObject[ 0 ] , 'origin' ) is true
        priorityList = { 'required' : 0 , 'custom-fn' : 1 , 'user' : 2 , 'validation' : 3 , 'mutation-fn' : 4 , 'compute-fn' : 5 , 'system' : 6 }
        errorDetailsObject = errorDetailsObject.sort ( left , right ) =>
          return priorityList[ left.origin ] - priorityList[ right.origin ]
        newErrorDetailList = []
        for item in errorDetailsObject
          if ( item.message in newErrorDetailList ) is false
            newErrorDetailList.push item.message
        errorDetailsObject = newErrorDetailList
      else
        idx = 0
        for item in errorDetailsObject
          errorDetailsObject[ idx ] = @_sortErrorMessageListBasedOnPriority item
          idx++
    else
      for key , value of errorDetailsObject
        errorDetailsObject[ key ] = @_sortErrorMessageListBasedOnPriority value
    return errorDetailsObject

  _operateOnEachInstanceOfAProperty : ( jsonSignature , pathList , parentPropertyName , propertyName , suppliedObject , errorDetails , res , parentList , arrayIndexUsage , errorDetailsMessagesPath ) =>
    if propertyName is 'ROOT_OBJECT'
      if ( JSON.stringify errorDetails.ROOT_OBJECT ) != '{}'
        error = new Error
        error.errorDetails = @_sortErrorMessageListBasedOnPriority errorDetails.ROOT_OBJECT
        throw error

    if pathList.length is 0
      if ( ConstantHelper.isNotNull res , parentPropertyName ) is false
        res[ parentPropertyName ] = {}

      res[ parentPropertyName ] = @_extractMethodExecution suppliedObject , propertyName , jsonSignature , parentList , errorDetails , res[ parentPropertyName ] , suppliedObject , arrayIndexUsage , errorDetailsMessagesPath

      if propertyName is 'ROOT_OBJECT'
        if ( JSON.stringify errorDetails.ROOT_OBJECT ) != '{}'
          error = new Error
          error.errorDetails = errorDetails.ROOT_OBJECT
          throw error

      return res

    pathItem = pathList[ 0 ]
    newPathList = pathList.slice 1 , pathList.length

    if jsonSignature.type is 'object'
      newJsonSignature = jsonSignature.map[ pathItem ]
      newVal = suppliedObject[ pathItem ]
      if ( ConstantHelper.isNotNull res , parentPropertyName ) is false
        res[ parentPropertyName ] = {}
      newErrorDetailsMessagesPath = ( item for item in errorDetailsMessagesPath )
      newErrorDetailsMessagesPath.push pathItem
      res[ parentPropertyName ] = @_operateOnEachInstanceOfAProperty newJsonSignature , newPathList , pathItem , propertyName , newVal , errorDetails , res[ parentPropertyName ] , parentList , arrayIndexUsage , newErrorDetailsMessagesPath

    else if jsonSignature.type is 'array'
      if ( ConstantHelper.isNotNull suppliedObject ) is false
        res[ parentPropertyName ] = suppliedObject
      else
        newJsonSignature = jsonSignature.def[ pathItem ]
        if ( ConstantHelper.isNotNull res , parentPropertyName ) is false
          res[ parentPropertyName ] = []
        idx = 0
        suppliedArray = suppliedObject
        for item in suppliedArray
          if ( idx >= res[ parentPropertyName ].length )
            i = 0
            while ( i < ( idx - res[ parentPropertyName ].length + 1 ) )
              res[ parentPropertyName ].push {}
              i++
          if ( ConstantHelper.isNotNull res[ parentPropertyName ][ idx ] , pathItem ) is false
            res[ parentPropertyName ][ idx ][ pathItem ] = {}
          newVal = suppliedObject[ idx ][ pathItem ]
          newArrayIndexUsage = ( item for item in arrayIndexUsage )
          newArrayIndexUsage.push { 'property' : parentPropertyName , 'index' : idx }
          newErrorDetailsMessagesPath = ( item for item in errorDetailsMessagesPath )
          newErrorDetailsMessagesPath.push 'ARRAY-ITEM'
          newErrorDetailsMessagesPath.push idx
          newErrorDetailsMessagesPath.push pathItem
          res[ parentPropertyName ][ idx ] = @_operateOnEachInstanceOfAProperty newJsonSignature , newPathList , pathItem , propertyName , newVal , errorDetails , res[ parentPropertyName ][ idx ] , parentList , newArrayIndexUsage , newErrorDetailsMessagesPath
          idx++

    else if jsonSignature.type is 'schema'
      # TO-DO

    else
      newVal = suppliedObject[ pathItem ]
      if ( ConstantHelper.isNotNull res , parentPropertyName ) is false
        res[ parentPropertyName ] = {}
      res[ parentPropertyName ] = @_operateOnEachInstanceOfAProperty jsonSignature , newPathList , pathItem , propertyName , newVal , errorDetails , res[ parentPropertyName ] , parentList , arrayIndexUsage , errorDetailsMessagesPath
    return res

  extract : ( suppliedObject ) =>
    res = {}
    @globalSuppliedObject = suppliedObject
    @globalRes = res
    errorDetails = { 'ROOT_OBJECT' : {} }
    for obj in @orderedPropertyListWithPath
      pathListWithoutRootObject = obj.pathList.slice 1 , obj.pathList.length
      @_operateOnEachInstanceOfAProperty @schemaJsonSignature , pathListWithoutRootObject , obj.pathList[ 0 ] , obj.propertyName , suppliedObject , errorDetails , res , obj.pathList , [] , [ 'ROOT_OBJECT' ]

    return res.ROOT_OBJECT

  ## Recursive property merger for static merge method.
  @propertyMerger : ( schemaJsonSignatureList , suppressCyclicDataErrors ) =>
    res = {}
    for schemaJsonSignatureObject in schemaJsonSignatureList
      for key , value of schemaJsonSignatureObject
        if key is 'map'
          for secondKey, secondValue of value
            if @self[ secondKey ] is null || ( typeof @self[ secondKey ] ) is ConstantHelper.undefinedString
              @self[ secondKey ] = true

              if res[ key ] is null || ( typeof res[ key ] ) is ConstantHelper.undefinedString
                res[ key ] = {}

              res[ key ][ secondKey ] = @propertyMerger [ secondValue ] , suppressCyclicDataErrors
            else
              if suppressCyclicDataErrors is false
                error = new Error
                error.errorDetails = 'Cyclic property found while merge operation.'
                throw error

        else
          res[ key ] = value
    return res

  ## Merge two or more schemas into a new schema. Existing schemas are not be altered in any way. Recursive propertyMerger is
  ## used here.
  @merge : ( schemaList... ) =>
    if schemaList.length is 0
      return schemaList
    res = new Schema {}
    res.allowNull = true
    propertyList = []
    # merge the schemaOption property from schemaList
    for schemaObject in schemaList
      # if the "allowNull" property is set for any schemaObject in schemaList, set the property to null on the resultant schemaObject
      if schemaObject.allowNull != null && ( typeof schemaObject.allowNull ) != ConstantHelper.undefinedString && schemaObject.allowNull is false
        schemaObject.allowNull = false

      if schemaObject.schemaOptions != null && ( typeof schemaObject.schemaOptions ) != ConstantHelper.undefinedString

        if schemaObject.schemaOptions.suppressCyclicDataErrors != null && ( typeof schemaObject.schemaOptions.suppressCyclicDataErrors ) != ConstantHelper.undefinedString
          if schemaObject.schemaOptions.suppressCyclicDataErrors is true
            res.schemaOptions.suppressCyclicDataErrors = true

        if schemaObject.schemaOptions.ignoreUnidentifiedData != null && ( typeof schemaObject.schemaOptions.ignoreUnidentifiedData ) != ConstantHelper.undefinedString
          if schemaObject.schemaOptions.ignoreUnidentifiedData is true
            res.schemaOptions.ignoreUnidentifiedData = true

      if propertyList.length > 0 && schemaObject.schemaJsonSignature.type != propertyList[ propertyList.length - 1 ].type
        error = new Error
        error.errorDetails = 'Two different property type found in the schemaList. The two types are: ' + schemaObject.schemaJsonSignature.type + ' and ' + propertyList[ propertyList.length - 1 ].type
        throw error

      propertyList.push schemaObject.schemaJsonSignature

    @self = {}
    # merge the actual schema recursively at schemaJsonSignature properties
    res.schemaJsonSignature = @propertyMerger propertyList , res.schemaOptions.suppressCyclicDataErrors

    res.topoSortObj = new TopoSort()
    res.topoSortObj.passSchemaJsonSignature res.schemaJsonSignature
    res.orderedPropertyListWithPath = res.topoSortObj.runTopologicalSort()
    return res

@Schema = Schema
