###
  class TopologicalSort
###

{ ConstantHelper } = require './constant-helper'

class TopologicalSort
  @graphAdjList : null
  @timeCounter : null

  constructor : () ->
    @_clearGraph()

  _clearGraph : () ->
    @graphAdjList = {}
    @reverseGraphAdjList = {}
    @visitedProperties = {}
    @vis = []
    @timeCounter = 1
    @rootPropertyName = 'ROOT_OBJECT'
    @globalSchemaJsonSignature = {}
    @propertyChildList = {}
    @propertyPathList = {}

  _addNewDirectedEdge : ( source , destination ) ->
    if source is destination
      return

    if ( ConstantHelper.isNotNull @graphAdjList , source ) is false
      @graphAdjList[ source ] = []

    @graphAdjList[ source ].push destination

    if ( ConstantHelper.isNotNull @reverseGraphAdjList , destination ) is false
      @reverseGraphAdjList[ destination ] = []

    @reverseGraphAdjList[ destination ].push source

  passSchemaJsonSignature : ( schemaJsonSignature ) ->
    @globalSchemaJsonSignature = schemaJsonSignature
    @visitedProperties = {}
    @_buildChildListFromSchema @globalSchemaJsonSignature , [ @rootPropertyName ] , @rootPropertyName

  _calculatePropertyPath : ( parameterList , parentList ) ->
    paramPathList = []

    for singleParameter in parameterList
      if singleParameter is '.'
        wholePathFromRoot = ( item for item in parentList )
        paramPathList.push wholePathFromRoot
        continue

      computeParentList = singleParameter.split '^'
      numberOfParents = computeParentList.length - 1
      computeChildList = computeParentList[ computeParentList.length - 1 ].split '.'
      requiredParentList = parentList.slice 0 , ( parentList.length - numberOfParents )
      requiredParentList = requiredParentList.slice 1 , requiredParentList.length

      if ( computeChildList.length is 1 and computeChildList[ 0 ] is '' )
        wholePathFromRoot = requiredParentList
      else
        wholePathFromRoot = requiredParentList.concat computeChildList

      paramPathList.push wholePathFromRoot

    return paramPathList

  _buildChildListFromSchema : ( schemaJsonSignature , parentList , currentPropertyName ) =>
    currentNodeChildList = []
    childObject = {}
    if ( ConstantHelper.isNotNull schemaJsonSignature , 'map' ) is true
      childObject = schemaJsonSignature.map
    if ( ConstantHelper.isNotNull schemaJsonSignature , 'def' ) is true
      childObject = schemaJsonSignature.def

    for newPropertyName , schemaObject of childObject
      if( ConstantHelper.isNotNull @visitedProperties , newPropertyName ) is false
        @visitedProperties[ newPropertyName ] = true
        @_addNewDirectedEdge currentPropertyName , newPropertyName

        currentNodeChildList.push newPropertyName

        newParentList = ( item for item in parentList )
        newParentList.push newPropertyName

        @_buildChildListFromSchema schemaObject , newParentList , newPropertyName

        @_buildChildListFromCustomFunctionParams schemaObject , newParentList , newPropertyName
        @_buildChildListFromValidationParams schemaObject , newParentList , newPropertyName

    @propertyChildList[ currentPropertyName ] = currentNodeChildList
    @propertyPathList[ currentPropertyName ] = parentList

  _buildChildListFromValidationParams : ( schemaJsonSignature , parentList , sourcePropertyName ) ->
    if ( ConstantHelper.isNotNull schemaJsonSignature , 'validation' ) is true
      if ( ConstantHelper.isNotNull schemaJsonSignature.validation , 'custom' ) is true
        if ( ConstantHelper.isNotNull schemaJsonSignature.validation.custom , 'params' ) is true
          paramPathList = @_calculatePropertyPath schemaJsonSignature.validation.custom.params , parentList
          for item in paramPathList
            destinationPropertyName = item[ item.length - 1 ]
            @_addNewDirectedEdge sourcePropertyName , destinationPropertyName

  _buildChildListFromCustomFunctionParams : ( schemaJsonSignature , parentList , sourcePropertyName ) ->
    if ( ConstantHelper.isNotNull schemaJsonSignature , 'compute' ) is true
      if ( ConstantHelper.isNotNull schemaJsonSignature.compute , 'params' ) is true
        paramPathList = @_calculatePropertyPath schemaJsonSignature.compute.params , parentList
        for item in paramPathList
          destinationPropertyName = item[ item.length - 1 ]
          @_addNewDirectedEdge sourcePropertyName , destinationPropertyName

  _runFirstDfs : ( parentPropertyName ) =>
    if ( ConstantHelper.isNotNull @visitedProperties , parentPropertyName ) is true
      return
    @visitedProperties[ parentPropertyName ] = @timeCounter
    childList = @graphAdjList[ parentPropertyName ]
    if ( ConstantHelper.isNotNull childList ) is true
      for child in childList
        if( ConstantHelper.isNotNull @visitedProperties , child ) is false
          @_runFirstDfs child

    @orderedNodeList.push { 'property' : parentPropertyName , 'timeCounterValue' : @timeCounter }
    @timeCounter++

  _runSecondDfs : ( parentPropertyName , color ) =>
    if ( ConstantHelper.isNotNull @coloredProperties , parentPropertyName ) is true
      return
    @coloredProperties[ parentPropertyName ] = color
    childList = @reverseGraphAdjList[ parentPropertyName ]
    if ( ConstantHelper.isNotNull childList ) is true
      for child in childList
        if( ConstantHelper.isNotNull @coloredProperties , child ) is false
          @_runSecondDfs child , color

  _runThirdDfs : ( parentPropertyName , color ) =>
    if ( ConstantHelper.isNotNull @visitedProperties , parentPropertyName ) is true
      return
    @visitedProperties[ parentPropertyName ] = color
    childList = @graphAdjList[ parentPropertyName ]
    if ( ConstantHelper.isNotNull childList ) is true
      for child in childList
        if ( ( ConstantHelper.isNotNull @visitedProperties , child ) is false ) and ( @coloredProperties[ child ] is color )
          @_runThirdDfs child , color
        else if ( ( ConstantHelper.isNotNull @visitedProperties , child ) is true ) and ( @visitedProperties[ child ] is color )
          error = new Error
          error.errorDetails = 'Cycle found in topological sorting.'
          throw error

  runTopologicalSort : () ->
    @orderedNodeList = []
    @visitedProperties = {}
    @_runFirstDfs @rootPropertyName

    @orderedNodeList = @orderedNodeList.sort ( left , right ) ->
      return left.timeCounterValue - right.timeCounterValue

    res = []
    for obj in @orderedNodeList
      res.push { 'propertyName' : obj.property , 'pathList' : @propertyPathList[ obj.property ] }

    @orderedNodeList = @orderedNodeList.sort ( left , right ) ->
      return right.timeCounterValue - left.timeCounterValue

    @coloredProperties = {}
    color = 1
    for obj in @orderedNodeList
      @_runSecondDfs obj.property , color
      color++

    # Checks for cycles
    @visitedProperties = {}
    for obj in @orderedNodeList
      @_runThirdDfs obj.property , @coloredProperties[ obj.property ]

    @_clearGraph()
    return res

@TopoSort = TopologicalSort
