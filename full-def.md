
# Simple Example

mySchema = new Schema {
  type: 'object'
  allowNull : true/false
  map :
    name:
      type: string
      minLength: 300
    postList:
      type : 'array'
      array : [ 1 , 2 , 3 , 5 , 6 ]
      allowNull : false
      minCount : 0
      maxCount : 100
      def :
        type : 'object'
        map :
          title :
            type : 'string'
          content :
            type : 'string'

}

# Types

* literal (string|number)
* string
* number (integer|float)
* integer
* float
* boolean
* object
* array
* schema (points to another schema basically)

## initiation

These properties are initialized with values in constructor unless specified in options.

* suppressCyclicDataErrors ( default false )
* ignoreUnidentifiedData ( default false )
* alwaysEscapeHtml ( default false ) details: https://github.com/bbs-enterprise/bbs-toolkit/issues/9

## all types

all types have these property -

* allowNull = true/false [default false] as boolean
* validation (described at the end)
* type = type of the property as string from above type list

## type : 'object'

This indicates that the data must be an object.

Properties -

* map - an object containing the keys this object is expected to have. each key has it's own definiton.

## type : 'array'

This indicates that the data must be a array.

Properties -

* minCount - the array must contain at least this many items, [default 0]
* maxCount - the array must contain at most this many items, [default infinity]
* def - def is an object that defines the schema for members of the array. (array members must have the same signature)

## type : 'literal'

This indicates that the value must be a string or a number.

* minLength [default 0]
* maxLength [default infinity]

## type : 'string', inherits 'literal'

This indicates that the value must be a string.

Properties -

* matchesExactly
* startsWith
* endsWith
* contains
* doesNotContain
* allowCharset (i.e. allowCharset: ‘0123456789ABCDEF’ here means hex input only) to-do
* regex (checks against provided regular expression) to-do
* escapeHtml details: https://github.com/bbs-enterprise/bbs-toolkit/issues/9
## type : 'number', inherits 'literal'

This indicates that the value must be a number.

Properties -

* tryToCoerce = true/false [default false] - this indicates whether we will apply 'parseFloat' during extraction if string encountered
* minValue [default -infinity]
* maxValue [default infinity]

## type : 'integer', inherits 'number'

This indicates that the value must be a integer.

Properties -

* tryToCoerce = true/false [default false] - this indicates whether we will apply 'parseInt' during extraction if string encountered

## type : 'float', inherits 'number'

This indicates that the value must be a float.

Properties -

* maxPrecision = [default infinity (or a really big number)] - maximum decimal precision allowed. If crossed, no error is thrown. Rather it is rounded using the roundingStrategy
* roundingStrategy = 'ceil', 'floor', 'approximate'. [default 'approximate'] - how we should round the float.  'approximate' means (if (number < floor(number)+0.5) then (number) else (number + 1))

## type : 'boolean'

This indicates that the value must be a boolean.

## type : 'schema'

This indicates that the schea should be loaded from another schema.

Properties -

* schema - another schema that is instanceof Schema. definition of the target schema is NOT copied. rather the control is delegated to the target schema then returned back to the parent schema. i.e. postSchema.extract in turn calls commentSchema.extract and so on.


# the 'validation' property
the validation property allows for custom rules, complete with three boolean logic gates. AND, OR, NOT.
there is a 'message' property that allows for a custom message to be shown if the validation fails.

Note that mutatator properties (i.e. maxPrecision or roundingStrategy) must not be inside the validation property.

# the mutation function named as 'mutationFn'

This function executes after the value of the property has been executed. Purpose of this function is to process the expected value
one last time before it is released out. Signature of this function as follows:

mutationFn : ( value ) ->
  return value

# the compute function names as 'compute'

'compute' function serves options like array join.
Sample schema using 'compute' function below.
userDataSchema = new Schema {
 type : 'object'
 allowNull : false
 __mapOrderedKeyList: []
 validation : {}
 map : {
   firstName : {
     type : 'string'
     allowNull : false
     validation : {
       minLength : 1
       maxLength : 256
     }
   }
   lastName : {
     type : 'string'
     allowNull : false
     validation : {
       minLength : 1
       maxLength : 256
     }
   }
   fullName: {
     type: 'string'
     compute: {
       params: [
         '^firstName'
         '^lastName'
       ]
       fn : (firstName, lastName) -> return firstName + ' ' + lastName
     }
     validation: .. as usual ..
   }
 }
}

# NOTES

* type : 'float', inherits 'number' means that all the validation props applicable to number should be applicable to float. it does not imply that internal implementation needs to be using inheritance.
* error message list ordering :
{
message: 'The supplied value of ' + propertyName + ' is not a float, it is expected to be a float.’
code: ‘ERR_FLOAT_FLOAT_EXPECTED’
origin: ‘user'
}
undecided ERR_UNDECIDED
custom fn = ‘custom-fn'
compute fn = ‘compute-fn'
mutationfn = ‘mutation-fn’
user provided validation message = ‘user’
built in messages for validation = ‘validation’
others = ‘system'

required = ‘required’
Priority order: [ 'required' , 'custom-fn' , 'user' , 'validation' , 'mutation-fn' , 'compute-fn' , 'system' ]
