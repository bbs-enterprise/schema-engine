{ expect } = require 'chai'

{ ConstantHelper } = require './../constant-helper'
{ Schema } = require './../schema'

describe 'Schema-Data-Suit' , =>

  describe '#merge' , =>

    describe '#testSuit-1' , =>

      userCommonSchema = new Schema {
        type : 'object'
        allowNull : false
        validation : {}
        map : {
          name : {
            type : 'string'
            allowNull : false
            validation : {
              message : 'Invalid Name'
              AND : [
                {
                  minLength : 3
                  maxLength : 256
                }
                {
                  NOT : {
                    OR : [ {
                      contains : [
                        'aa'
                        'bb'
                        'cc'
                      ]
                    } ]
                  }
                }
              ]
            }
          }
          email : {
            type : 'string'
            allowNull : false
            validation : {
              minLength : 3
              maxLength : 256
              validateAs : 'email'
            }
          }
        }
      }
      userFormInputSchema = Schema.merge( userCommonSchema , new Schema {
        type : 'object'
        allowNull : false
        validation : {}
        map : {
          password : {
            type : 'string'
            allowNull : false
            validation : {
              minLength : 8
              maxLength : 256
            }
          }
        }
      } )
      formData = {
        name : 'ak'
        email : 'ak@example.com'
        password: '12345678'
      }

      it '1. Expect extract() to just throw exception for providing a invalid object.' , =>
        _fn = () =>
          userFormInputSchema.extract formData
        expect( _fn ).to.throw Error

      it '2. Expect extract() to throw exception object with appropriate property details regarding exception. Name doen\'t have minimum length.' , =>
        try
          userFormInputSchema.extract formData
        catch ex
          result = ex.errorDetails
          expect( result ).to.have.property( 'name' ).to.be.a( 'array' ).have.length 2

      it '3. Expect extract() to throw exception object with appropriate property details regarding exception. Name doen\'t have minimum length and invalid email.' , =>
        formData = {
          name : 'ak'
          email : '@example.com'
          password : '12345678'
        }
        try
          userFormInputSchema.extract formData
        catch ex
          result = ex.errorDetails
          expect( result ).to.have.property 'name'
          expect( result ).to.have.property 'email'

      it '4. Expect extract() to throw exception object with appropriate property details regarding exception. Name have invalid substring.' , =>
        formData = {
          name : 'aatest'
          email : 'test-1@example.com'
          password : '12345678'
        }
        _fn = () =>
          userFormInputSchema.extract formData
        expect( _fn ).to.throw Error
        try
          userFormInputSchema.extract formData
        catch ex
          result = ex.errorDetails
          expect( result ).to.have.property 'name'
          expect( result ).not.to.have.property 'email'

    describe '#testSuit-2' , =>

      firstSampleComplexObject = {
        type : 'object'
        allowNull : false
        validation : {}
        map : {
          name : {
            type : 'string'
            allowNull : false
            validation : {}
            map: {}
          }
          email : {
            type : 'string'
            allowNull : false
            validation : {}
            map: {}
          }
          address : {
            type : 'object'
            allowNull : false
            validation : {}
            map : {
              house : {
                type : 'string'
                allowNull : false
                validation : {}
                map : {}
              }
              road : {
                type : 'string'
                allowNull : false
                validation : {}
                map : {}
              }
            }
          }
        }
      }
      firstSchema = new Schema firstSampleComplexObject
      secondSchema = new Schema {
        type : 'object'
        allowNull : false
        validation : {}
        map : {
          phone : {
            type : 'number'
            allowNull : false
            validation : {}
            map: {}
          }
        }
      }
      thirdSchema = Schema.merge firstSchema , secondSchema

      it '1. Expect merge() to return proper object properties.', =>
        expect( thirdSchema ).to.be.a( 'object' )
        expect( thirdSchema ).to.have.a.property( 'schemaOptions' )
        expect( thirdSchema ).to.have.a.property( 'schemaJsonSignature' )

        schemaJsonSignature = thirdSchema.schemaJsonSignature
        expect( schemaJsonSignature ).to.have.a.property( 'allowNull' )
        expect( schemaJsonSignature ).to.have.a.property( 'type' )
        expect( schemaJsonSignature ).to.have.a.property( 'validation' )
        if schemaJsonSignature.type is ConstantHelper.objectString
          expect( schemaJsonSignature ).to.have.a.property( 'map' )

      it '2. Expect merge() to throw cyclic property error due to "suppressCyclicDataErrors" has default value of false.', =>
        firstSampleComplexObject.map.address.map.phone = {
          type : 'string'
          allowNull : false
          validation : {}
          map : {}
        }
        firstSchema = new Schema firstSampleComplexObject
        thirdSchema = {}
        _fn = () =>
          thirdSchema = Schema.merge firstSchema , secondSchema
        expect( _fn ).to.throw( Error )

      it '3. Expect merge() to suppress cyclic property due to "suppressCyclicDataErrors" has value set to true.' , =>
        firstSchema = new Schema firstSampleComplexObject , { suppressCyclicDataErrors : true }
        thirdSchema = {}
        _fn = () =>
          thirdSchema = Schema.merge firstSchema , secondSchema
        expect( _fn ).to.not.throw( Error )

    describe '#testSuit-3', =>

      it '1. Expect merge() to throw error because of trying to merge two different type of objects.' , =>
        firstSchema = new Schema {
          type : 'object'
          allowNull : false
          map : {}
        }
        secondSchema = new Schema {
          type : 'number'
          allowNull : false
        }
        _fn = () =>
          thirdSchema = Schema.merge firstSchema , secondSchema
        expect( _fn ).to.throw( Error )

  describe '#isValid' , =>

    describe '#testSuit-1' , =>

      it '1. Expect isValid() to return false for not satisfying minimum length of object value which is a string.' , =>
        testSchema = new Schema {
          type : 'object'
          allowNull : false
          validation : {}
          map : {
            a : {
              type : 'string'
              allowNull : false
              validation : {
                minLength: 30
              }
            }
          }
        }
        results = testSchema.isValid { a : 'small string' }
        expect( results ).to.be.false

      it '2. Expect isValid() to return false for not satisfying minimum length of a string.' , =>
        testSchema = new Schema {
          type : 'string'
          allowNull : false
          validation : {
            minLength: 30
          }
        }
        results = testSchema.isValid 'A plain string'
        expect( results ).to.be.false

    describe '#testSuit-2' , =>

      userCommonSchema = new Schema {
        type : 'object'
        allowNull : false
        validation : {}
        map : {
          name : {
            type : 'string'
            allowNull : false
            validation : {
              minLength : 3
              maxLength : 256
            }
          }
          email : {
            type : 'string'
            allowNull : false
            validation : {
              minLength : 3
              maxLength : 256
              validateAs : 'email'
            }
          }
        }
      }

      userFormInputSchema = Schema.merge( userCommonSchema , new Schema {
        type : 'object'
        allowNull : false
        validation : {}
        map : {
          password : {
            type : 'string'
            allowNull : false
            validation : {
              minLength : 8
              maxLength : 256
            }
          }
        }
      } )

      userDbSchema = Schema.merge( userCommonSchema , new Schema( {
        type : 'object'
        allowNull : false
        validation : {}
        map : {
          passwordHash : {
            type : 'string'
            allowNull : false
            validation : {
              minLength : 8
              maxLength : 256
            }
          }
        }
      } ) )

      formData = {
        name : 'John Doe'
        email : 'john@example.com'
        password : '12345678'
      }

      it '1. Expect isValid() to return true for providing a valid object that satisfies the schema.' , =>
        results = userFormInputSchema.isValid formData
        expect( results ).to.be.true

      it '2. Expect isValid() to return true for providing a valid object after extracting data-object from extract() method.' , =>
        userData = userCommonSchema.extract formData
        expect( userData ).to.have.a.property( 'name' ).to.equal( 'John Doe' )
        expect( userData ).to.have.a.property( 'email' ).to.equal( 'john@example.com' )
        userData.passwordHash = ( require 'crypto' ).createHash( 'sha256' ).update( formData.password , 'utf8' ).digest( 'base64' )
        results = userDbSchema.isValid userData
        expect( results ).to.be.true

    describe '#testSuit-3' , =>

      userCommonSchema = new Schema {
        type : 'object'
        allowNull : false
        validation : {}
        map : {
          name : {
            type : 'string'
            allowNull : false
            validation : {
              message : 'Invalid Name'
              AND : [
                {
                  minLength : 3
                  maxLength : 256
                }
                { NOT : {
                  OR : [
                    {
                      contains : [
                        'aa'
                        'bb'
                        'cc'
                      ]
                    }
                  ]
                } }
              ]
            }
          }
          email : {
            type : 'string'
            allowNull : false
            validation : {
              minLength : 3
              maxLength : 256
              validateAs : 'email'
            }
          }
        }
      }
      userFormInputSchema = Schema.merge( userCommonSchema , new Schema {
        type : 'object'
        allowNull : false
        validation : {}
        map : {
          password : {
            type : 'string'
            allowNull : false
            validation : {
              minLength : 8
              maxLength : 256
            }
          }
        }
      } )
      userDbSchema = Schema.merge( userCommonSchema , new Schema {
        type : 'object'
        allowNull : false
        validation : {}
        map : {
          passwordHash : {
            type : 'string'
            allowNull : false
            validation : {
              minLength : 8
              maxLength : 256
            }
          }
        }
      } )
      formData = {
        name : 'John Doe'
        email : 'john@example.com'
        password : '12345678'
      }

      it '1. Expect isValid() to return true for providing a valid object that satisfies the schema.' , =>
        results = userFormInputSchema.isValid formData
        expect( results ).to.be.true

      it '2. Expect isValid() to return true for providing a valid object that satisfies the schema.' , =>
        userData = userCommonSchema.extract formData
        userData.passwordHash = ( require 'crypto' ).createHash( 'sha256' ).update( formData.password , 'utf8' ).digest( 'base64' )
        results = userDbSchema.isValid userData
        expect( results ).to.be.true

      it '3. Expect extract() to return false for providing a invalid object with not satisfying minimum length of "name" property.' , =>
        formData = {
          name : 'ak'
          email : 'ak@example.com'
          password : '12345678'
        }
        results = userDbSchema.isValid formData
        expect( results ).to.be.false

    describe '#testSuit-4' , =>

      firstSchema =  new Schema {
        type : 'object'
        allowNull : false
        validation : {}
        map : {
          name : {
            type : 'string'
            allowNull : false
            minLength : 3
            maxLength : 256
            validation : {
              message : 'Invalid Name'
              AND : [
                { NOT : {
                  OR : [
                    {
                      contains : [
                        'aa'
                        'bb'
                        'cc'
                      ]
                    }
                  ]
                } }
              ]
            }
          }
          email : {
            type : 'string'
            allowNull : false
            validation : {
              minLength : 3
              maxLength : 256
              validateAs : 'email'
            }
          }
        }
      }

      data = {
        name : 'John Doe'
        email : 'john@example.com'
        password : '12345678'
      }

      it '1. Expect isValid() to return true for providing a valid object that satisfies the schema.' , =>
        results = firstSchema.isValid data
        expect( results ).to.be.true

  describe '#extract' , =>

    describe '#testSuit-1' , =>

      userCommonSchema = new Schema {
        type : 'object'
        allowNull : false
        validation : {}
        map : {
          name : {
            type : 'string'
            allowNull : false
            validation : {
              message : 'Invalid Name'
              AND : [
                {
                  minLength : 3
                  maxLength : 256
                }
                {
                  NOT : {
                    OR : [ {
                      contains : [
                        'aa'
                        'bb'
                        'cc'
                      ]
                    } ]
                  }
                }
              ]
            }
          }
          email : {
            type : 'string'
            allowNull : false
            validation : {
              minLength : 3
              maxLength : 256
              validateAs : 'email'
            }
          }
        }
      }
      userFormInputSchema = Schema.merge( userCommonSchema , new Schema {
        type : 'object'
        allowNull : false
        validation : {}
        map : {
          password : {
            type : 'string'
            allowNull : false
            validation : {
              minLength : 8
              maxLength : 256
            }
          }
        }
      } )
      formData = {
        name : 'ak'
        email : 'ak@example.com'
        password: '12345678'
      }

      it '1. Expect extract() to just throw exception for providing a invalid object.' , =>
        _fn = () =>
          userFormInputSchema.extract formData
        expect( _fn ).to.throw Error

      it '2. Expect extract() to throw exception object with appropriate property details regarding exception. Name doen\'t have minimum length.' , =>
        try
          userFormInputSchema.extract formData
        catch ex
          result = ex.errorDetails
          expect( result ).to.have.property 'name'
          expect( result ).not.to.have.property 'email'
          expect( result ).not.to.have.property 'password'

      it '3. Expect extract() to throw exception object with appropriate property details regarding exception. Name doen\'t have minimum length and invalid email.' , =>
        formData = {
          name : 'ak'
          email : '@example.com'
          password : '12345678'
        }
        try
          userFormInputSchema.extract formData
        catch ex
          result = ex.errorDetails
          expect( result ).to.have.property 'name'
          expect( result ).to.have.property 'email'

      it '4. Expect extract() to throw exception object with appropriate property details regarding exception. Name have invalid substring.' , =>
        formData = {
          name : 'aatest'
          email : 'test-1@example.com'
          password : '12345678'
        }
        _fn = () =>
          userFormInputSchema.extract formData
        expect( _fn ).to.throw Error
        try
          userFormInputSchema.extract formData
        catch ex
          result = ex.errorDetails
          expect( result ).to.have.property 'name'
          expect( result ).not.to.have.property 'email'

    describe '#testSuit-2' , =>

      userCommonSchema = new Schema {
        type : 'object'
        allowNull : false
        validation : {}
        map : {
          name : {
            type : 'string'
            validation : {
              message : 'Invalid Name'
              AND : [
                {
                  minLength : 3
                  maxLength : 256
                }
                { NOT :
                  { AND : [
                    { contains : [
                      'aa'
                      'bb'
                      'cc'
                    ] }
                  ] }
                }
              ]
            }
          }
          email : {
            type : 'string'
            minLength : 17
            maxLength : 256
            validateAs : 'email'
          }
        }
      }
      userFormInputSchema = Schema.merge( userCommonSchema , new Schema( {
        type : 'object'
        allowNull : false
        validation : {}
        map : {
          password : {
            type : 'string'
            allowNull : false
            validation : {
              minLength : 8
              maxLength : 256
            }
          }
        }
      } ) )

      it '1. Expect extract() not to throw exception because the data is valid according to schema.', =>
        formData = {
          name : 'aatest'
          email : 'test-1@example.com'
          password : '12345678'
        }
        _fn = () =>
          userFormInputSchema.extract formData
        expect(_fn).not.to.throw Error

      it '2. Expect extract() to throw exception object with appropriate property details regarding exception. Name have invalid substring.' , =>
        formData = {
          name : 'aabbcctest'
          email : 'test-2@example.com'
          password : '12345678'
        }
        _fn = () =>
          userFormInputSchema.extract formData
        expect( _fn ).to.throw Error
        try
          userFormInputSchema.extract formData
        catch ex
          result = ex.errorDetails
          expect( result ).to.have.property 'name'
          expect( result ).not.to.have.property 'email'

    describe '#testSuit-3 : tests complex validation object against supplied data.' , =>

      userCommonSchema = new Schema {
        name : {
          type : 'string'
          validation : {
            message : 'Invalid Name'
            AND : [
              {
                minLength : 3
                maxLength : 256
              }
              {
                NOT : {
                  AND : [
                    { contains : [
                      'aa'
                      'bb'
                      'cc'
                    ] }
                  ]
                }
              }
            ]
          }
        }
        email : {
          type : 'string'
          minLength : 17
          maxLength : 256
          validateAs : 'email'
        }
      }
      userFormInputSchema = Schema.merge( userCommonSchema , new Schema {
        password : {
          type : 'string'
          minLength : 8
          maxLength : 256
        }
      } )

      it '1. Expect extract() not to throw exception because the data is valid according to schema.' , =>
        formData = {
          name : 'aatest'
          email : 'test-1@example.com'
          password : '12345678'
        }
        _fn = () =>
          userFormInputSchema.extract formData
        expect( _fn ).not.to.throw Error

    describe '#testSuit-4 : checks custom function value return and expected error throw.' , =>

      userDataSchema = new Schema {
        type : 'object'
        allowNull : false
        validation : {}
        map : {
          password : {
            type : 'string'
            allowNull : false
            validation : {
              minLength : 1
              maxLength : 256
            }
          }
          repeatedPassword : {
            type : 'string'
            allowNull : false
            validation : {
              message : 'Invalid repeated password'
              custom : {
                message : 'expected passwords to be equal in custom validation function'
                params : [
                  '^password'
                  '.'
                ]
                fn : ( password , repeatedPassword ) -> return password is repeatedPassword
              }
            }
          }
        }
      }

      it '1. Expect extract() to throw exception because of custom function returning false.' , =>
        formData = {
          password : 'test-1@example.com'
          repeatedPassword : 'test-2@example.com'
        }
        _fn = () =>
          userDataSchema.extract formData
        expect( _fn ).to.throw Error
        try
          userDataSchema.extract formData
        catch ex
          expect( ex ).to.have.a.property 'errorDetails'
          errorDetails = ex.errorDetails
          expect( errorDetails ).to.have.a.property 'repeatedPassword'
          passwordErrorDetails = errorDetails.repeatedPassword
          expect( passwordErrorDetails ).to.be.a( 'array' )
          expect( passwordErrorDetails ).to.have.length 2
          expect( passwordErrorDetails ).to.include 'expected passwords to be equal in custom validation function'
          expect( passwordErrorDetails ).to.include 'Invalid repeated password'

      it '2. Expect extract() not to throw exception because of custom function returning true.' , =>
        formData = {
          password : 'test-1@example.com'
          repeatedPassword : 'test-1@example.com'
        }
        _fn = () =>
          userDataSchema.extract formData
        expect( _fn ).not.to.throw Error

    describe '#testSuit-5 : expectes custom validation function to throw error because it returns non-boolean value.', =>

      it '1. Expect extract() to throw error because of custom validator function returns non-boolean value.' , =>
        userDataSchemaJson = {
          type : 'object'
          allowNull : false
          validation : {}
          map : {
            password : {
              type : 'string'
              allowNull : false
              validation : {
                minLength : 1
                maxLength : 256
              }
            }
            repeatedPassword : {
              type : 'string'
              allowNull : false
              validation : {
                message : 'Invalid repeated password'
                custom : {
                  message : 'expected passwords to be equal in custom validation function'
                  params : [
                    '^password'
                    '.'
                  ]
                  fn : ( parameterList ) -> return 1000000007
                }
              }
            }
          }
        }

        formData = {
          password : 'test-1@example.com'
          repeatedPassword : 'test-1@example.com'
        }
        userDataSchema = new Schema userDataSchemaJson
        _fn = () =>
          userDataSchema.extract formData
        expect( _fn ).to.throw Error
        try
          userDataSchema.extract formData
        catch ex
          expect( ex ).to.have.a.property 'errorDetails'
          errorDetails = ex.errorDetails
          expect( errorDetails ).to.have.a.property 'repeatedPassword'
          repeatedPasswordErrorMessages = errorDetails.repeatedPassword
          expect( repeatedPasswordErrorMessages ).to.include 'Error thrown from custom validator function of "repeatedPassword" property.'
          expect( repeatedPasswordErrorMessages ).to.include 'Unrecognized value returned from custom validator function of "repeatedPassword" property. Expected the value to be boolean.'
          expect( repeatedPasswordErrorMessages ).to.include 'expected passwords to be equal in custom validation function'
          expect( repeatedPasswordErrorMessages ).to.include 'Invalid repeated password'

    describe '#testSuit-6 : tests compute property usage.' , =>
      userDataSchemaJson = {
        type : 'object'
        allowNull : false
        validation : {}
        map : {
          firstName : {
            type : 'string'
            allowNull : false
            validation : {
              minLength : 1
              maxLength : 256
            }
            mutationFn : ( value ) ->
              return 'Mr. ' + value
          }
          lastName : {
            type : 'string'
            allowNull : false
            validation : {
              minLength : 1
              maxLength : 256
            }
          }
          fullName : {
            type : 'string'
            allowNull : false
            compute : {
              params : [
                '^firstName'
                '^lastName'
              ]
              fn : ( firstName , lastName ) ->
                return firstName + ' ' + lastName
            }
            validation : {
              minLength : 1
              maxLength : 256
            }
          }
        }
      }

      userData = {
        firstName : 'John'
        lastName : 'Doe'
        fullName : ''
      }

      it '1. Expect contructor() to order child properties based on the existance of "compute" property and store the resultant key in an array.' , =>
        userDataSchema = new Schema userDataSchemaJson
        expect( userDataSchema ).to.have.a.property 'schemaJsonSignature'
        expect( userDataSchema.schemaJsonSignature ).to.have.a.property '__mapOrderedKeyList'
        mapOrderedKeyList = userDataSchema.schemaJsonSignature.__mapOrderedKeyList
        expect( mapOrderedKeyList ).to.have.members [ 'firstName' , 'lastName' , 'fullName' ]
        expect( mapOrderedKeyList ).to.have.length 3

      it '2. Expect extract to call mutation function if the property value.' , =>
        userDataSchema = new Schema userDataSchemaJson
        extractedData = userDataSchema.extract userData
        expect( extractedData ).to.have.property 'firstName'
        expect( extractedData.firstName ).to.equal 'Mr. John'
        expect( extractedData ).to.have.property 'lastName'
        expect( extractedData.lastName ).to.equal 'Doe'
        expect( extractedData ).to.have.property 'fullName'
        expect( extractedData.fullName ).to.equal 'Mr. John Doe'

    describe '#testSuit-7 : tests error throwing mechanism including error details messsages for \'extract \' method. Also tests mutation functionality.' , =>
      userDataSchemaJson = {
        type : 'object'
        allowNull : false
        validation : {}
        map : {
          firstName : {
            type : 'string'
            allowNull : true
            validation : {
              minLength : 1
              maxLength : 256
            }
            mutationFn : ( value ) ->
              return 'Mr. ' + value
          }
          lastName : {
            type : 'string'
            allowNull : false
            validation : {
              minLength : 9
              maxLength : 256
            }
          }
        }
      }

      it '1. Expect extract() to throw array due to not satisfying required minimum length.' , =>
        userData = {
          firstName : 'John'
          lastName : 'Doe'
        }
        userDataSchema = new Schema userDataSchemaJson
        _fn = () ->
          data = userDataSchema.extract userData
        expect( _fn ).to.throw Error
        try
          data = userDataSchema.extract userData
        catch ex
          expect( ex ).to.have.a.property( 'errorDetails' )
          errorDetails = ex.errorDetails
          expect( errorDetails ).to.have.a.property( 'lastName' )
          errorList = errorDetails.lastName
          expect( errorList ).to.be.a( 'array' )
          expect( errorList ).to.have.length( 2 )
          expect( errorList ).to.include( 'Minimum length not satisfied of lastName. Expected length of at least 9 and received a length of 3' )
          expect( errorList ).to.include( 'Validation error in "lastName" property (custom error message not provided in schema signature).' )

      it '2. Expect extract() to return proper value object.' , =>
        userData = {
          firstName : 'John'
          lastName : 'Mikkelsen'
        }
        userDataSchema = new Schema userDataSchemaJson
        data = userDataSchema.extract userData
        expect( data ).to.have.a.property 'firstName'
        expect( data ).to.have.a.property( 'firstName' ).to.equal 'Mr. John'
        expect( data ).to.have.a.property 'lastName'
        expect( data ).to.have.a.property( 'lastName' ).to.equal 'Mikkelsen'

    describe 'testSuit-8 : A complex real world test case with almost all necessary components.' , =>

      passwordStrengthCheckingFunction = ( password ) ->
        return 'acceptable'

      userDataSchemaJson =
        type : 'object'
        map :
          name :
            type : 'object'
            #customEvaluationOrder : [ 'last' , 'first' , 'middle' , 'honorifics' ]
            map :
              honorifics :
                type : 'string'
                allowNull : true
                validation :
                  OR : [
                    { contains : 'Mr' }
                    { contains : 'Mss' }
                    { contains : 'Miss' }
                    { contains : 'Dr' }
                  ]
              first :
                type : 'string'
                validation :
                  minLength : 2
                  maxLength : 32
              middle :
                type : 'string'
                allowNull : true
                validation :
                  minLength : 2
                  maxLength : 64
              last :
                type : 'string'
                validation :
                  minLength : 2
                  maxLength : 32
          greetAs :
            type : 'string'
            compute :
              params : [ '^name.honorifics' , '^name.first' , '^name.middle' , '^name.last' ]
              fn : ( honorifics , first , middle , last) ->
                ( if honorifics then honorifics + ' ' else '' ) + first + ' ' + ( if middle then middle + ' ' else '' ) + last
            validation :
              minLength : 4
          password :
            type : 'string'
            minLength : 8
            maxLength : 64
            validation :
              custom :
                params : [ '.' ]
                fn : ( password ) ->
                  if ( passwordStrengthCheckingFunction password ) is 'acceptable'
                    return true
                  else
                    return false
          repeatedPassword :
            type : 'string'
            validation :
              custom :
                params : [ '^password' , '.' ]
                fn : ( password , repeatedPassword ) -> password is repeatedPassword
          registrationDateTime :
            type : 'integer'
            validation :
              custom :
                params : [ '.' ]
                fn : ( value ) -> 0 < ( new Date ).getTime() - ( new Date value ).getTime() < 10 * 365 * 24 * 60 * 60 * 1000
            mutate :
              fn : ( value ) -> ( new Date value )

      exampleUser =
        name :
          honorifics : 'Mr'
          first : 'John'
          middle : 'Winston'
          last : 'Lennon'
        password : 'Working Class Hero Is Something To Be'
        repeatedPassword : 'Working Class Hero Is Something To Be'
        registrationDateTime : 1437721697343

      it '1. Test for \'Schema\' class proper object creation.' , =>
        userDataSchema = new Schema userDataSchemaJson

        expect( userDataSchema ).to.have.a.property( 'schemaOptions' )
        schemaOptions = userDataSchema.schemaOptions
        expect( schemaOptions ).to.be.a( 'object' )
        expect( schemaOptions ).to.have.a.property( 'suppressCyclicDataErrors' )
        expect( schemaOptions ).to.have.a.property( 'suppressCyclicDataErrors' ).to.be.a( 'boolean' )
        expect( schemaOptions ).to.have.a.property( 'suppressCyclicDataErrors' ).to.be.false
        expect( schemaOptions ).to.have.a.property( 'ignoreUnidentifiedData' )
        expect( schemaOptions ).to.have.a.property( 'ignoreUnidentifiedData' ).to.be.a( 'boolean' )
        expect( schemaOptions ).to.have.a.property( 'ignoreUnidentifiedData' ).to.be.false
        expect( userDataSchema ).to.have.a.property( 'schemaJsonSignature' )
        expect( userDataSchema ).to.have.a.property( 'schemaJsonSignature' ).to.be.a( 'object' )

      it '2. Test for data extraction from given data.' , =>
        userDataSchema = new Schema userDataSchemaJson
        _fn = () ->
          userDataSchema.extract exampleUser
        expect( _fn ).not.to.throw Error
        try
          data = userDataSchema.extract exampleUser
        catch ex
          #console.log ex.message , ex.stack
          throw ex

    describe 'testSuit-9 : testing exptected array value return.' , =>

      passwordStrengthCheckingFunction = ( password ) ->
        return 'acceptable'

      phoneNumberSchemaJson =
        type : 'object'
        map :
          numbers :
            type : 'array'
            allowNull : false
            def :
              countryCode :
                type : 'integer'
                allowNull : false
                validation : {}
              areaCode :
                type : 'integer'
                allowNull : false
                validation : {}
              completeNumber :
                type : 'string'
                compute :
                  params : [ '^countryCode' , '^areaCode' ]
                  fn : ( countryCode , areaCode ) ->
                    return '' + countryCode + '-' + areaCode
          numbersCount :
            type : 'integer'
            compute :
              params : [ '^numbers' ]
              fn : ( numbers ) ->
                res = numbers.length
                return res
      phoneNumberList =
        numbers : [
          {
            countryCode : 1
            areaCode : 204
          }
          {
            countryCode : 2
            areaCode : 720
          }
          {
            countryCode : 3
            areaCode : 962
          }
        ]
      phoneNumberSchema = new Schema phoneNumberSchemaJson

      it '1. Test for \'array\' schema-object-type value formatting of extracted data from \'extract\' method.' , =>
        _fn = () ->
          phoneNumberSchema.extract phoneNumberList
        expect( _fn ).not.to.throw Error
        try
          data = phoneNumberSchema.extract phoneNumberList
        catch ex
          console.log ex.message , ex.stack

        expect( data ).to.have.a.property( 'numbers' ).to.be.a( 'array' )
        numbers = data.numbers
        expect( numbers ).to.have.length( 3 )
        idx = 0
        for number in numbers
          expect( number ).to.be.a( 'object' )
          expect( number ).to.have.a.property( 'countryCode' ).equals( phoneNumberList.numbers[ idx ].countryCode ).to.be.a( 'number' )
          expect( number ).to.have.a.property( 'areaCode' ).equals( phoneNumberList.numbers[ idx ].areaCode ).to.be.a( 'number' )
          idx++

    describe 'testSuit-10 : Registration Schema extract data format checking including \'array\' type object.' , =>

      passwordStrengthCheckingFunction = ( password ) ->
        return 'acceptable'

      userRegistrationSchemaJson =
        type : 'object'
        map :
          profile :
            type : 'object'
            map :
              name :
                type : 'object'
                #customEvaluationOrder : [ 'last' , 'first' , 'middle' , 'honorifics' ]
                map :
                  honorifics :
                    type : 'string'
                    allowNull : true
                    validation :
                      OR : [
                        { contains : 'Mr' }
                        { contains : 'Mss' }
                        { contains : 'Miss' }
                        { contains : 'Dr' }
                      ]
                  first :
                    type : 'string'
                    allowNull : false
                    validation :
                      minLength : 2
                      maxLength : 32
                  middle :
                    type : 'string'
                    allowNull : true
                    validation :
                      minLength : 2
                      maxLength : 64
                  last :
                    type : 'string'
                    allowNull : false
                    validation :
                      minLength : 2
                      maxLength : 32
              greetAs :
                type : 'string'
                compute :
                  params : [ '^name.honorifics' , '^name.first' , '^name.middle' , '^name.last' ]
                  fn : ( honorifics , first , middle , last) ->
                    ( if honorifics then honorifics + ' ' else '' ) + first + ' ' + ( if middle then middle + ' ' else '' ) + last
                validation :
                  minLength : 4

              dateOfBirth :
                type : 'integer'
                validation :
                  custom :
                    params : [ '.' ]
                    fn : ( value ) -> 0 < ( new Date ).getTime() - ( new Date value ).getTime() < 10 * 365 * 24 * 60 * 60 * 1000
                mutate :
                  fn : ( value ) -> ( new Date value )

              nationalIdCardNumber :
                type : 'string'
                allowNull : false
                validation :
                  minLength : 20
                  maxLength : 32

              emailList :
                type : 'array'
                allowNull : false
                def :
                  address :
                    type : 'string'
                    validation :
                      custom :
                        params : [ '.' ]
                        fn : ( value ) ->
                          emailRegex = /^([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$/i
                          return emailRegex.test value
                  isPrimary :
                    type : 'boolean'
                    allowNull : false

      exampleUser =
        profile:
          name :
            honorifics : 'Mr'
            first : 'John'
            middle : 'Winston'
            last : 'Lennon'
          dateOfBirth : 1437721697343
          nationalIdCardNumber : '1234567891011121314151617'
          emailList : [
            {
              address : 'asif@a.com'
              isPrimary : true
            }
            {
              address : 'asif@a.com'
              isPrimary : false
            }
          ]
      it '1. Expect extract() to return proper value object.' , =>
        try
          userDataSchema = new Schema userRegistrationSchemaJson
        catch ex
          console.log ex.errorDetails
        userDataSchema = new Schema userRegistrationSchemaJson
        data = {}
        _fn = () ->
          data = userDataSchema.extract exampleUser
        expect( _fn ).not.to.throw( Error )

        expect( data ).to.have.a.property( 'profile' )
        expect( data.profile ).to.have.a.property( 'name' ).to.be.a( 'object' )
        expect( data.profile.name ).to.have.property( 'honorifics' ).to.be.a( 'string' ).to.equal( 'Mr' )
        expect( data.profile.name ).to.have.property( 'first' ).to.be.a( 'string' ).to.equal( 'John' )
        expect( data.profile.name ).to.have.property( 'middle' ).to.be.a( 'string' ).to.equal( 'Winston' )
        expect( data.profile.name ).to.have.property( 'last' ).to.be.a( 'string' ).to.equal( 'Lennon' )

        expect( data.profile ).to.have.property( 'dateOfBirth' ).to.be.a( 'number' )
        expect( data.profile ).to.have.property( 'nationalIdCardNumber' ).to.be.a( 'string' )

        expect( data.profile ).to.have.property( 'emailList' ).to.be.a( 'array' )
        expect( data.profile.emailList[ 0 ] ).to.have.property( 'address' ).to.be.a( 'string' )
        expect( data.profile.emailList[ 0 ] ).to.have.property( 'isPrimary' ).to.be.a( 'boolean' )
        expect( data.profile.emailList[ 1 ] ).to.have.property( 'address' ).to.be.a( 'string' )
        expect( data.profile.emailList[ 1 ] ).to.have.property( 'isPrimary' ).to.be.a( 'boolean' )

      it '2. Expect schemaJson to have appropriate property.' , =>
        userDataSchema = new Schema userRegistrationSchemaJson

        expect( userDataSchema).to.have.property( 'schemaJsonSignature' )
        schemaJsonSignature = userDataSchema.schemaJsonSignature
        expect( schemaJsonSignature ).to.have.property( 'type' ).equals( 'object' )
        expect( schemaJsonSignature ).to.have.property( 'map' ).to.be.a( 'object' )
        expect( schemaJsonSignature ).to.have.property( 'allowNull' ).equals( true )
        expect( schemaJsonSignature ).to.have.property( 'validation' ).to.deep.equal( {} )

        map = userDataSchema.schemaJsonSignature.map

        expect( map ).to.have.property( 'profile' ).to.be.a( 'object' )

        profile = userDataSchema.schemaJsonSignature.map.profile

      it '3. Expected not to throw error in \'array\' object type' , =>
        userDataSchema = new Schema userRegistrationSchemaJson

        _fn = () =>
          userDataSchema.extract exampleUser

        expect( _fn ).not.to.throw Error

    describe 'testSuit-11 : checks for whether or not valid integer is provided or not.' , =>

      passwordStrengthCheckingFunction = ( password ) ->
        return 'acceptable'

      ageSchemaJson =
        type : 'object'
        allowNull : false
        map :
          age :
            type : 'integer'
            allowNull : false

      it '1. Expect extract() to throw error due to providing object instead of integer.' , =>
        ageValue = { test : 1 }
        ageSchema = new Schema ageSchemaJson
        _fn = () =>
          data = ageSchema.extract age
        expect( _fn ).to.throw Error

      it '2. Expect extract() to throw error due to providing folat instead of integer' , =>
        age = { age : 12.89 }
        ageSchema = new Schema ageSchemaJson
        _fn = () =>
          data = ageSchema.extract age
        expect( _fn ).to.throw Error

      it '3. Expect extract() to throw error due to providing string instead of integer' , =>
        age = { age : '12.89' }
        ageSchema = new Schema ageSchemaJson
        _fn = () =>
          data = ageSchema.extract age
        expect( _fn ).to.throw Error

    describe '#testSuit-12 : testing the Topological sort algorithm.' , =>

      userCommonSchemaSignature = {
        type : 'object'
        allowNull : false
        validation : {}
        map : {
          name : {
            type : 'string'
            allowNull : false
            validation : {}
          }
          email : {
            type : 'string'
            allowNull : false
            validation : {}
          }
          password : {
            type : 'string'
            allowNull : false
            validation : {
              minLength : 8
              maxLength : 256
            }
          }
          passwordHash : {
            type : 'string'
            allowNull : false
            validation : {}
            compute : {
              params : [ '^password' ]
              fn : ( password ) ->
                return '------' + password
            }
          }
        }
      }

      userData = {
        name : 'ak'
        email : 'ak@example.com'
        password : '12345678'
      }

      it '1. Expect extract() to not throw error for using topological sort integration to extract method.' , =>
        _fn = () =>
          data = userCommonSchema.extract userData
        userCommonSchema = new Schema userCommonSchemaSignature
        expect( _fn ).not.to.throw Error
        data = userCommonSchema.extract userData
        expect( data ).to.have.a.property( 'name' ).equals( 'ak' )
        expect( data ).to.have.a.property( 'email' ).equals( 'ak@example.com' )
        expect( data ).to.have.a.property( 'password' ).equals( '12345678' )
        expect( data ).to.have.a.property( 'passwordHash' ).equals( '------12345678' )

    describe 'testSuit-13 : Checks for cycle in schema json signature definition.' , =>

      it '1. Expect to throw error because of a cycle of two nodes.' , =>
        userJsonSignature = {
          type : 'object'
          map :
            name :
              type : 'string'
              compute :
                params : [ '^email' ]
                fn : ( email ) ->
                  return '....' + email
            email :
              type : 'string'
              compute :
                params : [ '^name' ]
                fn : ( name ) ->
                  return '****' + name
        }
        _fn = () =>
          userSchema = new Schema userJsonSignature
        expect( _fn ).to.throw Error
        try
          userSchema = new Schema userJsonSignature
        catch ex
          expect( ex ).to.have.a.property( 'errorDetails' ).to.be( 'string' )

      it '2. Expect to throw error because of a cycle of three nodes.' , =>
        userJsonSignature = {
          type : 'object'
          map :
            name :
              type : 'string'
              compute :
                params : [ '^email' ]
                fn : ( email ) ->
                  return '....' + email
            email :
              type : 'string'
              compute :
                params : [ '^address' ]
                fn : ( address ) ->
                  return '****' + address
            address :
              type : 'string'
              compute :
                params : [ '^name' ]
                fn : ( name ) ->
                  return '-----' + name
        }
        _fn = () =>
          userSchema = new Schema userJsonSignature
        expect( _fn ).to.throw Error
        try
          userSchema = new Schema userJsonSignature
        catch ex
          expect( ex ).to.have.a.property( 'errorDetails' ).to.be( 'string' )

      it '3. Expect not to throw error because of no cycle present.' , =>
        userJsonSignature = {
          type : 'object'
          map :
            name :
              type : 'string'
              compute :
                params : [ '^email' ]
                fn : ( email ) ->
                  return '....' + email
            email :
              type : 'string'
              compute :
                params : [ '^address' ]
                fn : ( address ) ->
                  return '****' + address
            address :
              type : 'string'
        }
        _fn = () =>
          userSchema = new Schema userJsonSignature
        expect( _fn ).not.to.throw Error

    describe 'testSuit-14 : Error thrown from complex object schema json signature construction. This error is thrown from topological sorting algorithm.' , =>

      passwordStrengthCheckingFunction = ( password ) ->
        return 'acceptable'

      userRegistrationSchemaJson =
        type : 'object'
        map :
          profile :
            type : 'object'
            map :
              name :
                type : 'object'
                map :
                  honorifics :
                    type : 'string'
                    allowNull : true
                    validation :
                      OR : [
                        { contains : 'Mr' }
                        { contains : 'Mss' }
                        { contains : 'Miss' }
                        { contains : 'Dr' }
                      ]
                  first :
                    type : 'string'
                    allowNull : false
                    validation :
                      minLength : 2
                      maxLength : 32
                  middle :
                    type : 'string'
                    allowNull : true
                    validation :
                      minLength : 2
                      maxLength : 64
                  last :
                    type : 'string'
                    allowNull : false
                    validation :
                      minLength : 2
                      maxLength : 32
              greetAs :
                type : 'string'
                compute :
                  params : [ '^name.honorifics' , '^name.first' , '^name.middle' , '^name.last' ]
                  fn : ( honorifics , first , middle , last) ->
                    ( if honorifics then honorifics + ' ' else '' ) + first + ' ' + ( if middle then middle + ' ' else '' ) + last
                validation :
                  minLength : 4

              dateOfBirth :
                type : 'integer'
                validation :
                  custom :
                    params : [ '.' ]
                    fn : ( value ) -> 0 < ( new Date ).getTime() - ( new Date value ).getTime() < 10 * 365 * 24 * 60 * 60 * 1000
                mutate :
                  fn : ( value ) -> ( new Date value )

              nationalIdCardNumber :
                type : 'string'
                allowNull : false
                validation :
                  minLength : 20
                  maxLength : 32

              emailList :
                type : 'array'
                allowNull : false
                def :
                  address :
                    type : 'string'
                    validation :
                      custom :
                        params : [ '.' ]
                        fn : ( value ) ->
                          emailRegex = /^([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$/i
                          return emailRegex.test value
                  isPrimary :
                    type : 'boolean'
                    allowNull : false
                    validation :
                      custom :
                        params : [ '^^' ]
                        fn : ( value ) ->
                          cn = 0
                          for item in value
                            cn++ if item.isPrimary is true
                          return true if cn is 1
                          return false

      exampleUser =
        profile:
          name :
            honorifics : 'Mr'
            first : 'John'
            middle : 'Winston'
            last : 'Lennon'
          dateOfBirth : 1437721697343
          nationalIdCardNumber : '1234567891011121314151617'
          emailList : [
            {
              address : 'asif@a.com'
              isPrimary : true
            }
            {
              address : 'asif@a.com'
              isPrimary : false
            }
          ]
      it '1. Expect extract() to return proper value object.' , =>
        _fn = () ->
          userDataSchema = new Schema userRegistrationSchemaJson
        expect( _fn ).to.throw( Error )
        try
          userDataSchema = new Schema userRegistrationSchemaJson
        catch ex
          expect( ex ).to.have.property( 'errorDetails' ).to.be.a( 'string' ).equals( 'Cycle found in topological sorting.' )

    describe '#testSuit-15: Real world test cases from BDERM api.' , =>

      it '1. Tests the whole user profile json signature' , =>

        userSignupJsonSignature = {
          type : 'object'
          allowNull : false
          map :
            key_type :
              allowNull : true
              type : 'string'
              validation :
                message : '"key_type" length should be between 3 and 32.'
                AND : [
                  {
                    minLength : 3
                    maxLength : 32
                  }
                ]
            bmdc_reg_number :
              allowNull : true
              type : 'integer'
              tryToCoerce : true
              validation :
                message : '"bmdc_reg_number" length should be between 4 and 5.'
                AND : [
                  {
                    minLength : 4
                    maxLength : 5
                  }
                ]
                custom :
                  params : [ '^key_type' , '^bmdc_reg_type' , '.' ]
                  fn : ( key_type , bmdc_reg_type , bmdc_reg_number ) ->
                    if key_type is 'doctor'
                      if isNaN( parseInt( bmdc_reg_number ) ) && ( typeof bmdc_reg_number ) is 'string'
                        err = new Error
                        err.customErrorMessage = 'BMDC Reg No. must only contain digits.'
                        throw err
                      if( bmdc_reg_type is 'Medical' )
                        if ( '' + bmdc_reg_number ).length is 5
                          return true
                        else
                          err = new Error
                          err.customErrorMessage = 'BMDC Reg No. for Medical should be 5 Digit Long. i.e for Medical 1-71000'
                          throw err
                          return false
                      else if( bmdc_reg_type is 'Dental' )
                        if ( '' + bmdc_reg_number ).length is 4
                          return true
                        else
                          err = new Error
                          err.customErrorMessage = 'BMDC Reg No. for Dental should be 4 Digit Long. i.e for Dental 1-6100'
                          throw err
                          return false
                      else
                        err = new Error
                        err.customErrorMessage = 'Unrecognized BMDC registration type.'
                        throw err
                    else if key_type is 'patient'
                      if bmdc_reg_number is null || ( typeof bmdc_reg_number ) is 'undefined'
                        return true
                      return false
              mutationFn : ( bmdc_reg_number ) ->
                if bmdc_reg_number is null || ( typeof bmdc_reg_number ) is 'undefined'
                  return bmdc_reg_number
                return '1-' + bmdc_reg_number
            bmdc_reg_type :
              allowNull : true
              type : 'string'
              validation :
                message : '"bmdc_reg_type" length should be between 1 and 32.'
                AND : [
                  {
                    minLength : 1
                    maxLength : 32
                  }
                ]
                custom :
                  params : [ '^key_type' , '.' ]
                  fn : ( key_type , bmdc_reg_type ) ->
                    if key_type is 'doctor'
                      if bmdc_reg_type in [ 'Medical' , 'Dental' ]
                        return true
                      else
                        err = new Error
                        err.customErrorMessage = 'Please select BMDC Registration Type.'
                        throw err
                        return false
                    else if key_type is 'patient'
                      if bmdc_reg_type is null || ( typeof bmdc_reg_type ) is 'undefined'
                        return true
                      return false
            user_nid :
              allowNull : true
              type : 'integer'
              tryToCoerce : true
              validation :
                message : 'Please provide valid national ID.'
                AND : [
                  {
                    minLength : 5
                    maxLength : 128
                  }
                ]
                custom :
                  params : [ '^key_type' , '.' ]
                  fn : ( key_type , user_nid ) ->
                    if key_type is 'doctor'
                      if user_nid is null || ( typeof user_nid ) is 'undefined'
                        return true
                      return false
                    else if key_type is 'patient'
                      if user_nid is null || ( typeof user_nid ) is 'undefined'
                        err = new Error
                        err.customErrorMessage = 'National ID can\'t be empty.'
                        throw err
                        return false
                      return true
            user_salutation :
              allowNull : false
              type : 'string'
              validation :
                message : '"user_salutation" length should be between 1 and 32.'
                AND : [
                  {
                    minLength : 1
                    maxLength : 128
                  }
                ]
                custom :
                  params : [ '.' ]
                  fn : ( user_salutation ) ->
                    if user_salutation in [ 'Dr.' , 'Prof.' , "Mr." , "Miss" ]
                      return true
                    else
                      err = new Error
                      err.customErrorMessage = 'Please select Salutation.'
                      throw err
                      return false
            first_name :
              allowNull : false
              type : 'string'
              validation :
                message : 'Invalid First Name.'
                AND : [
                  {
                    minLength : 1
                    maxLength : 128
                  }
                ]
            last_name :
              allowNull : false
              type : 'string'
              validation :
                message : 'Invalid Last Name.'
                AND : [
                  {
                    minLength : 1
                    maxLength : 128
                  }
                ]
            password :
              allowNull : false
              type : 'string'
              validation :
                message : 'Invalid password.'
                AND : [
                  {
                    minLength : 12
                    maxLength : 128
                  }
                ]
                custom :
                  params : [ '.' ]
                  fn : ( password ) ->
                    len = password.length
                    fl = 0
                    for i in [ 0 .. len - 1 ]
                      if ( password.charCodeAt( i ) >= 'A'.charCodeAt( 0 ) && password.charCodeAt( i ) <= 'Z'.charCodeAt( 0 ) )
                        fl++
                        break
                    if fl is 0
                      err = new Error
                      err.customErrorMessage = 'At least 1(one) uppercase letter is required.'
                      throw err
                      return false
                    for i in [ 0 .. len - 1 ]
                      if ( password.charCodeAt( i ) >= '0'.charCodeAt( 0 ) && password.charCodeAt( i ) <= '9'.charCodeAt( 0 ) )
                        fl++
                        break
                    if fl is 1
                      err = new Error
                      err.customErrorMessage = 'At least 1(one) digit is required.'
                      throw err
                      return false
                    return true
            password_repeat :
              allowNull : false
              type : 'string'
              validation :
                message : 'Passwords doesn\'t match.'
                custom :
                  params : [ '^password' , '.' ]
                  fn : ( password , password_repeat ) ->
                    if password is password_repeat
                      return true
                    else
                      return false
            email_id_list :
              allowNull : false
              type : 'array'
              validation :
                custom :
                  message : 'Email id(s) required.'
                  params : [ '.' ]
                  fn : ( email_id_list ) ->
                    if email_id_list.length is 0
                      return false
                    return true
              def :
                email_type :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : '"email_type" length should be between 1 and 16.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 16
                      }
                    ]
                    custom :
                      params : [ '.' ]
                      fn : ( email_type ) ->
                        if email_type in [ 'primary' , 'secondary' , 'work' ]
                          return true
                        else
                          err = new Error
                          err.customErrorMessage = 'Please select email type.'
                          throw err
                          return false
                email_id :
                  allowNull : true
                  type : 'string'
                  validation :
                    message : 'Email address required.'
                    AND : [
                      {
                        minLength : 5
                        maxLength : 32
                      }
                    ]
                    custom :
                      params : [ '.' ]
                      fn : ( email_id ) ->
                        emailRegex = /^([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$/i
                        res = emailRegex.test email_id
                        if res is false
                          err = new Error
                          err.customErrorMessage = 'Please type valid email address.'
                          throw err
                        return res
            phone_number_list :
              allowNull : false
              type : 'array'
              validation :
                custom :
                  message : 'Phone number(s) required.'
                  params : [ '.' ]
                  fn : ( phone_number_list ) ->
                    if phone_number_list.length is 0
                      return false
                    return true
              def :
                phone_number_type :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Please select a phone number type.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 16
                      }
                    ]
                    custom :
                      params : [ '.' ]
                      fn : ( phone_number_type ) ->
                        if phone_number_type in [ 'primary' , 'main' , 'work' , 'home' ]
                          return true
                        else
                          err = new Error
                          err.customErrorMessage = 'Please select phone number type.'
                          throw err
                          return false
                phone_number :
                  allowNull : true
                  type : 'integer'
                  tryToCoerce : true
                  validation :
                    message : 'Please provide valid phone number. Sample: 01776546890'
                    AND : [
                      {
                        minLength : 11
                        maxLength : 11
                      }
                    ]
            fax_number_list :
              allowNull : true
              type : 'array'
              def :
                fax_number_type :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : '"fax_number_type" length should be between 1 and 16.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 16
                      }
                    ]
                    custom :
                      params : [ '.' ]
                      fn : ( phone_number_type ) ->
                        if phone_number_type in [ 'primary' , 'main' , 'work' , 'home' ]
                          return true
                        else
                          err = new Error
                          err.customErrorMessage = 'Please select fax number type.'
                          throw err
                          return false
                fax_number :
                  allowNull : true
                  type : 'integer'
                  tryToCoerce : true
                  validation :
                    message : 'Please provide valid fax number. Sample: 09776546890.'
                    AND : [
                      {
                        minLength : 11
                        maxLength : 11
                      }
                    ]
            dob :
              allowNull : false
              type : 'string'
              validation :
                message : 'Please provide valid date of birth.'
                AND : [
                  {
                    minLength : 8
                    maxLength : 10240
                  }
                ]
            gender :
              allowNull : false
              type : 'string'
              validation :
                message : 'Please select a gender.'
                AND : [
                  {
                    minLength : 4
                    maxLength : 16
                  }
                ]
            nationality :
              allowNull : false
              type : 'string'
              validation :
                message : 'Please provide your valid nationality.'
                AND : [
                  {
                    minLength : 3
                    maxLength : 64
                  }
                ]
            contact_list :
              allowNull : false
              type : 'array'
              validation :
                custom :
                  message : 'Contact(s) required.'
                  params : [ '.' ]
                  fn : ( contact_list ) ->
                    if contact_list.length is 0
                      return false
                    return true
              def :
                contact_label :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Contact title required.'
                    AND : [
                      {
                        minLength : 3
                        maxLength : 128
                      }
                    ]
                contact_type :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Contact type required.'
                    AND : [
                      {
                        minLength : 3
                        maxLength : 32
                      }
                    ]
                    custom :
                      params : [ '.' ]
                      fn : ( contact_type ) ->
                        if contact_type in [ 'primary' , 'main' , 'work' , 'home' , 'present' ]
                          return true
                        else
                          err = new Error
                          err.customErrorMessage = 'Contact type required.'
                          throw err
                          return false
                contact_address :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Contact address required.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 256
                      }
                    ]
                contact_map_latitude :
                  allowNull : true
                  type : 'float'
                  tryToCoerce : true
                  validation :
                    message : 'Invalid latitude. (Sample: 1.0)'
                    AND : [
                      {
                        minLength : 3
                        maxLength : 32
                      }
                    ]
                contact_map_longitude :
                  allowNull : true
                  type : 'float'
                  tryToCoerce : true
                  validation :
                    message : 'Invalid longitude. (Sample: 1.0)'
                    AND : [
                      {
                        minLength : 3
                        maxLength : 32
                      }
                    ]
                contact_city :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Invalid contact city.'
                    AND : [
                      {
                        minLength : 2
                        maxLength : 32
                      }
                    ]
                contact_state :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Invalid contact state.'
                    AND : [
                      {
                        minLength : 2
                        maxLength : 32
                      }
                    ]
                contact_zip :
                  allowNull : false
                  type : 'integer'
                  tryToCoerce : true
                  validation :
                    message : 'Invalid contact zip code.'
                    AND : [
                      {
                        minLength : 3
                        maxLength : 32
                      }
                    ]
                contact_country :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Invalid contact country.'
                    AND : [
                      {
                        minLength : 3
                        maxLength : 32
                      }
                    ]
            profile_image :
              allowNull : true
              type : 'string'
              validation :
                message : 'Profile image required.'
                AND : [
                  {
                    minLength : 1
                    maxLength : 31457280
                  }
                ]
            biography :
              allowNull : true
              type : 'string'
              validation :
                message : 'Invalid biography.'
                AND : [
                  {
                    minLength : 1
                    maxLength : 2048
                  }
                ]
            degree_list :
              allowNull : true
              type : 'array'
              validation :
                custom :
                  message : 'At least "MBBS" degree is required.'
                  params : [ '^key_type' , '.' ]
                  fn : ( key_type , degree_list ) ->
                    if key_type is 'doctor'
                      fl = false
                      for item in degree_list
                        if item.degree_title.toLowerCase() is 'MBBS'.toLowerCase()
                          fl = true
                          break
                      return fl
                    else if key_type is 'patient'
                      if degree_list is null || ( typeof degree_list ) is 'undefined'
                        return true
                      err = new Error
                      err.customErrorMessage = 'Degree list is not applicable for \'patient\' type users.'
                      throw err
                      return false
              def :
                degree_title :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Invalid degree title.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 128
                      }
                    ]
                degree_institution :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Please select Institution Name.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 128
                      }
                    ]
                degree_details :
                  allowNull : true
                  type : 'string'
                  validation :
                    message : 'Invalid degree details.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 512
                      }
                    ]
                degree_year :
                  allowNull : false
                  type : 'integer'
                  tryToCoerce : true
                  validation :
                    message : 'Invalid degree year.'
                    AND : [
                      {
                        minLength : 4
                        maxLength : 4
                      }
                    ]
                    custom :
                      message : 'Degree year has to be a valid year between 1930 and 2030.'
                      params : [ '.' ]
                      fn : ( degree_year ) ->
                        if degree_year < 1930 || degree_year > 2030
                          return false
                        return true
            family_member_list :
              allowNull : true
              type : 'array'
              def :
                family_member_name :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Family member name is required.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 128
                      }
                    ]
                family_member_relation :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Family member relation is required.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 128
                      }
                    ]
                family_member_phone_number :
                  allowNull : true
                  type : 'integer'
                  tryToCoerce : true
                  validation :
                    message : 'Invalid family member phone number.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 32
                      }
                    ]
                family_member_email_id :
                  allowNull : true
                  type : 'string'
                  validation :
                    message : 'Invalid family member email address.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 128
                      }
                    ]
                    custom :
                      params : [ '.' ]
                      fn : ( family_member_email_id ) ->
                        if family_member_email_id is null || ( typeof family_member_email_id ) == 'undefined'
                          return true
                        emailRegex = /^([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$/i
                        res = emailRegex.test family_member_email_id
                        if res is false
                          err = new Error
                          err.customErrorMessage = 'Please type valid email address.'
                          throw err
                        return res
                family_member_address :
                  allowNull : true
                  type : 'string'
                  validation :
                    message : 'Invalid family member address.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 256
                      }
                    ]
            employment_details :
              allowNull : true
              type : 'array'
              def :
                employment_status :
                  allowNull : false
                  type : 'boolean'
                employment_title :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Employment title is required.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 128
                      }
                    ]
                current_position :
                  allowNull : true
                  type : 'string'
                  validation :
                    message : 'Employment current position is required.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 128
                      }
                    ]
                company_title :
                  allowNull : true
                  type : 'string'
                  validation :
                    message : 'Invalid employment company title.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 512
                      }
                    ]
                company_address :
                  allowNull : true
                  type : 'string'
                  validation :
                    message : 'Invalid employment company address.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 512
                      }
                    ]
                company_web_link :
                  allowNull : true
                  type : 'string'
                  validation :
                    message : 'Invalid employment company web link.'
                    AND : [
                      {
                        minLength : 10
                        maxLength : 512
                      }
                    ]
                company_thumb :
                  allowNull : true
                  type : 'string'
                  validation :
                    message : 'Invalid employment company thumbnail image.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 31457280
                      }
                    ]
                salary_range :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Employment salary range is required.'
                    AND : [
                      {
                        minLength : 3
                        maxLength : 32
                      }
                    ]
            certification_list :
              allowNull : true
              type : 'array'
              def :
                certification_title :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Certification title is required.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 128
                      }
                    ]
                certification_institution :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Certification institution is required.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 128
                      }
                    ]
                certification_details :
                  allowNull : true
                  type : 'string'
                  validation :
                    message : 'Invalid certification details.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 512
                      }
                    ]
                certification_year :
                  allowNull : false
                  type : 'integer'
                  validation :
                    message : 'Certification year is required.'
                    AND : [
                      {
                        minLength : 4
                        maxLength : 4
                      }
                    ]
            publication_list :
              allowNull : true
              type : 'array'
              def :
                publication_title :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Publication title is required.'
                    AND : [
                      {
                        minLength : 3
                        maxLength : 128
                      }
                    ]
                publication_thumbnail :
                  allowNull : true
                  type : 'string'
                  validation :
                    message : 'Invalid publication thumbnail image.'
                    AND : [
                      {
                        minLength : 10
                        maxLength : 10240
                      }
                    ]
                publication_url :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Publication URL is required.'
                    AND : [
                      {
                        minLength : 10
                        maxLength : 512
                      }
                    ]
            social_connection_list :
              allowNull : true
              type : 'array'
              def :
                social_connection_title :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Social connection title is required.'
                    AND : [
                      {
                        minLength : 3
                        maxLength : 128
                      }
                    ]
                social_connection_thumbnail :
                  allowNull : true
                  type : 'string'
                  validation :
                    message : 'Invalid social connection thumbnail image.'
                    AND : [
                      {
                        minLength : 10
                        maxLength : 10240
                      }
                    ]
                social_connection_url :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Social connection URL is required.'
                    AND : [
                      {
                        minLength : 10
                        maxLength : 512
                      }
                    ]
            website_list :
              allowNull : true
              type : 'array'
              def :
                website_title :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Website title is required.'
                    AND : [
                      {
                        minLength : 5
                        maxLength : 128
                      }
                    ]
                website_thumbnail :
                  allowNull : true
                  type : 'string'
                  validation :
                    message : 'Invalid website thumbnail image.'
                    AND : [
                      {
                        minLength : 10
                        maxLength : 10240
                      }
                    ]
                website_url :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Website URL is required.'
                    AND : [
                      {
                        minLength : 10
                        maxLength : 512
                      }
                    ]
        }

        doctorSignupData = {
          key_type : 'doctor'
          bmdc_reg_number : '12345'
          bmdc_reg_type : 'Medical'
          user_nid : null
          user_salutation : 'Dr.'
          first_name : 'John'
          last_name : 'Doe'
          password : 'My password'
          password_repeat : 'My password'
          email_id_list : [
            {
              email_type : 'primary'
              email_id : 'john@example.com'
            }
          ]
          phone_number_list : [
            {
              phone_number_type : 'primary'
              phone_number : '01776546890'
            }
          ]
          dob : '20/10/1970'
          gender : 'Male'
          nationality : 'Bangladeshi'
          contact_list : [
            {
              contact_label : 'Jane Doe'
              contact_type : 'present'
              contact_address : '34 Main Street'
              contact_city : 'Los Angeles'
              contact_state : 'California'
              contact_zip : '90002'
              contact_country : 'United States'
            }
          ]
          profile_image : 'SGVsbG8sIHdvcmxk'
          degree_list : [
            {
              degree_title : 'MBBS'
              degree_institution : 'Johns Hopkins Medical College'
              degree_year : 1940
            }
          ]
        }

        patientSignupData = {
          key_type : 'patient'
          user_nid : '121212112123123'
          user_salutation : 'Dr.'
          first_name : 'John'
          last_name : 'Doe'
          password : 'My password'
          password_repeat : 'My password'
          email_id_list : [
            {
              email_type : 'primary'
              email_id : 'john@example.com'
            }
          ]
          phone_number_list : [
            {
              phone_number_type : 'primary'
              phone_number : '01776546890'
            }
          ]
          dob : '20/10/1970'
          gender : 'Male'
          nationality : 'Bangladeshi'
          contact_list : [
            {
              contact_label : 'Jane Doe'
              contact_type : 'present'
              contact_address : '34 Main Street'
              contact_city : 'Los Angeles'
              contact_state : 'California'
              contact_zip : '90002'
              contact_country : 'United States'
            }
          ]
          profile_image : 'SGVsbG8sIHdvcmxk'
        }

        try
          userSignupSchema = new Schema userSignupJsonSignature
          response = userSignupSchema.extract patientSignupData
          #console.log response , 1001
        catch ex
          #console.log ex.stack , 1002
          #console.log ex.errorDetails , 1000

      it '2. Tests the login json signature' , =>

        userLoginJsonSignature = {
          type : 'object'
          allowNull : false
          map :
            emailOrPhone :
              allowNull : true
              type : 'string'
              validation :
                message : 'Please provide a valid email address or phone number.'
                AND : [
                  {
                    minLength : 5
                    maxLength : 32
                  }
                ]
                custom :
                  params : [ '.' ]
                  fn : ( emailOrPhone ) ->
                    emailRegex = /^([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$/i
                    res = emailRegex.test emailOrPhone
                    if res is false
                      emailOrPhone = '' + emailOrPhone
                      if emailOrPhone.length isnt 11
                        err = new Error
                        err.customErrorMessage = 'Please provide a valid email address or phone number.'
                        throw err
                      else
                        res = true
                        len = emailOrPhone.length
                        for i in [ 0 .. len - 1 ]
                          if ! ( emailOrPhone.charCodeAt( i ) >= '0'.charCodeAt( 0 ) && emailOrPhone.charCodeAt( i ) <= '9'.charCodeAt( 0 ) )
                            err = new Error
                            err.customErrorMessage = 'Please provide a valid email address or phone number.'
                            throw err
                    return res
            password :
              allowNull : false
              type : 'string'
              validation :
                message : 'Invalid password.'
                AND : [
                  {
                    minLength : 8
                    maxLength : 128
                  }
                ]
        }

        emailLoginData = {
          emailOrPhone : 'c@a.com'
          password : 'asdasdasd'
        }

        phoneLoginData = {
          emailOrPhone : '01676546808'
          password : 'My password'
        }

        try
          userLoginSchema = new Schema userLoginJsonSignature
          response = userLoginSchema.extract emailLoginData
          #console.log response , 1001
        catch ex
          #console.log ex.message , ex.stack , 1002
          console.log ex.errorDetails , 1000

      it '3. Tests the contact-us json signature.' , =>

        contactUsJsonSignature = {
          type : 'object'
          allowNull : false
          map :
            name :
              allowNull : false
              type : 'string'
              validation :
                message : 'Please provide a valid name.'
                AND : [
                  {
                    minLength : 5
                    maxLength : 128
                  }
                ]
            email :
              allowNull : false
              type : 'string'
              validation :
                message : 'Please provide a valid email address.'
                AND : [
                  {
                    minLength : 5
                    maxLength : 32
                  }
                ]
                custom :
                  message : 'Please provide a valid email address.'
                  params : [ '.' ]
                  fn : ( email ) ->
                    emailRegex = /^([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$/i
                    res = emailRegex.test email
                    return res
            message :
              allowNull : false
              type : 'string'
              validation :
                message : 'Invalid message.'
                AND : [
                  {
                    minLength : 8
                    maxLength : 2048
                  }
                ]
        }

        contactUsData = {
          name : 'John Doe'
          email : 'asdasd@asasd.com'
          message : 'aaaaaaaa'
        }

        try
          contactUsSchema = new Schema contactUsJsonSignature
          response = contactUsSchema.extract contactUsData
          #console.log response , 1001
        catch ex
          #console.log ex.message , ex.stack , 1002
          console.log ex.errorDetails , 1000

      it '4. Tests the error details of user profile schema.' , =>

        userSignupJsonSignature = {
          type : 'object'
          allowNull : false
          map :
            key_type :
              allowNull : true
              type : 'string'
              validation :
                message : '"key_type" length should be between 3 and 32.'
                AND : [
                  {
                    minLength : 3
                    maxLength : 32
                  }
                ]
            bmdc_reg_number :
              allowNull : true
              type : 'integer'
              tryToCoerce : true
              validation :
                message : '"bmdc_reg_number" length should be between 4 and 5.'
                AND : [
                  {
                    minLength : 4
                    maxLength : 5
                  }
                ]
                custom :
                  params : [ '^key_type' , '^bmdc_reg_type' , '.' ]
                  fn : ( key_type , bmdc_reg_type , bmdc_reg_number ) ->
                    if key_type is 'doctor'
                      if isNaN( parseInt( bmdc_reg_number ) ) && ( typeof bmdc_reg_number ) is 'string'
                        err = new Error
                        err.customErrorMessage = 'BMDC Reg No. must only contain digits.'
                        throw err
                      if( bmdc_reg_type is 'Medical' )
                        if ( '' + bmdc_reg_number ).length is 5
                          return true
                        else
                          err = new Error
                          err.customErrorMessage = 'BMDC Reg No. for Medical should be 5 Digit Long. i.e for Medical 1-71000'
                          throw err
                          return false
                      else if( bmdc_reg_type is 'Dental' )
                        if ( '' + bmdc_reg_number ).length is 4
                          return true
                        else
                          err = new Error
                          err.customErrorMessage = 'BMDC Reg No. for Dental should be 4 Digit Long. i.e for Dental 1-6100'
                          throw err
                          return false
                      else
                        err = new Error
                        err.customErrorMessage = 'Unrecognized BMDC registration type.'
                        throw err
                    else if key_type is 'patient'
                      if bmdc_reg_number is null || ( typeof bmdc_reg_number ) is 'undefined'
                        return true
                      return false
              mutationFn : ( bmdc_reg_number ) ->
                if bmdc_reg_number is null || ( typeof bmdc_reg_number ) is 'undefined'
                  return bmdc_reg_number
                return '1-' + bmdc_reg_number
            bmdc_reg_type :
              allowNull : true
              type : 'string'
              validation :
                message : '"bmdc_reg_type" length should be between 1 and 32.'
                AND : [
                  {
                    minLength : 1
                    maxLength : 32
                  }
                ]
                custom :
                  params : [ '^key_type' , '.' ]
                  fn : ( key_type , bmdc_reg_type ) ->
                    if key_type is 'doctor'
                      if bmdc_reg_type in [ 'Medical' , 'Dental' ]
                        return true
                      else
                        err = new Error
                        err.customErrorMessage = 'Please select BMDC Registration Type.'
                        throw err
                        return false
                    else if key_type is 'patient'
                      if bmdc_reg_type is null || ( typeof bmdc_reg_type ) is 'undefined'
                        return true
                      return false
            user_nid :
              allowNull : true
              type : 'integer'
              tryToCoerce : true
              validation :
                message : 'Please provide valid national ID.'
                AND : [
                  {
                    minLength : 5
                    maxLength : 128
                  }
                ]
                custom :
                  params : [ '^key_type' , '.' ]
                  fn : ( key_type , user_nid ) ->
                    if key_type is 'doctor'
                      if user_nid is null || ( typeof user_nid ) is 'undefined'
                        return true
                      return false
                    else if key_type is 'patient'
                      if user_nid is null || ( typeof user_nid ) is 'undefined'
                        err = new Error
                        err.customErrorMessage = 'National ID can\'t be empty.'
                        throw err
                        return false
                      return true
            user_salutation :
              allowNull : false
              type : 'string'
              validation :
                message : '"user_salutation" length should be between 1 and 32.'
                AND : [
                  {
                    minLength : 1
                    maxLength : 128
                  }
                ]
                custom :
                  params : [ '.' ]
                  fn : ( user_salutation ) ->
                    if user_salutation in [ 'Dr.' , 'Prof.' , "Mr." , "Miss" ]
                      return true
                    else
                      err = new Error
                      err.customErrorMessage = 'Please select Salutation.'
                      throw err
                      return false
            first_name :
              allowNull : false
              type : 'string'
              validation :
                message : 'Invalid First Name.'
                AND : [
                  {
                    minLength : 1
                    maxLength : 128
                  }
                ]
            last_name :
              allowNull : false
              type : 'string'
              validation :
                message : 'Invalid Last Name.'
                AND : [
                  {
                    minLength : 1
                    maxLength : 128
                  }
                ]
            password :
              allowNull : false
              type : 'string'
              validation :
                message : 'Invalid password.'
                AND : [
                  {
                    minLength : 12
                    maxLength : 128
                  }
                ]
                custom :
                  params : [ '.' ]
                  fn : ( password ) ->
                    len = password.length
                    fl = 0
                    for i in [ 0 .. len - 1 ]
                      if ( password.charCodeAt( i ) >= 'A'.charCodeAt( 0 ) && password.charCodeAt( i ) <= 'Z'.charCodeAt( 0 ) )
                        fl++
                        break
                    if fl is 0
                      err = new Error
                      err.customErrorMessage = 'At least 1(one) uppercase letter is required.'
                      throw err
                      return false
                    for i in [ 0 .. len - 1 ]
                      if ( password.charCodeAt( i ) >= '0'.charCodeAt( 0 ) && password.charCodeAt( i ) <= '9'.charCodeAt( 0 ) )
                        fl++
                        break
                    if fl is 1
                      err = new Error
                      err.customErrorMessage = 'At least 1(one) digit is required.'
                      throw err
                      return false
                    return true
            password_repeat :
              allowNull : false
              type : 'string'
              validation :
                message : 'Passwords doesn\'t match.'
                custom :
                  params : [ '^password' , '.' ]
                  fn : ( password , password_repeat ) ->
                    if password is password_repeat
                      return true
                    else
                      return false
            email_id_list :
              allowNull : false
              type : 'array'
              validation :
                custom :
                  message : 'Email id(s) required.'
                  params : [ '.' ]
                  fn : ( email_id_list ) ->
                    if email_id_list.length is 0
                      return false
                    return true
              def :
                email_type :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : '"email_type" length should be between 1 and 16.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 16
                      }
                    ]
                    custom :
                      params : [ '.' ]
                      fn : ( email_type ) ->
                        if email_type in [ 'primary' , 'secondary' , 'work' ]
                          return true
                        else
                          err = new Error
                          err.customErrorMessage = 'Please select email type.'
                          throw err
                          return false
                email_id :
                  allowNull : true
                  type : 'string'
                  validation :
                    message : 'Email address required.'
                    AND : [
                      {
                        minLength : 5
                        maxLength : 32
                      }
                    ]
                    custom :
                      params : [ '.' ]
                      fn : ( email_id ) ->
                        emailRegex = /^([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$/i
                        res = emailRegex.test email_id
                        if res is false
                          err = new Error
                          err.customErrorMessage = 'Please type valid email address.'
                          throw err
                        return res
            phone_number_list :
              allowNull : false
              type : 'array'
              validation :
                custom :
                  message : 'Phone number(s) required.'
                  params : [ '.' ]
                  fn : ( phone_number_list ) ->
                    if phone_number_list.length is 0
                      return false
                    return true
              def :
                phone_number_type :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Please select a phone number type.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 16
                      }
                    ]
                    custom :
                      params : [ '.' ]
                      fn : ( phone_number_type ) ->
                        if phone_number_type in [ 'primary' , 'main' , 'work' , 'home' ]
                          return true
                        else
                          err = new Error
                          err.customErrorMessage = 'Please select phone number type.'
                          throw err
                          return false
                phone_number :
                  allowNull : true
                  type : 'integer'
                  tryToCoerce : true
                  validation :
                    message : 'Please provide valid phone number. Sample: 01776546890'
                    AND : [
                      {
                        minLength : 11
                        maxLength : 11
                      }
                    ]
            fax_number_list :
              allowNull : true
              type : 'array'
              def :
                fax_number_type :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : '"fax_number_type" length should be between 1 and 16.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 16
                      }
                    ]
                    custom :
                      params : [ '.' ]
                      fn : ( phone_number_type ) ->
                        if phone_number_type in [ 'primary' , 'main' , 'work' , 'home' ]
                          return true
                        else
                          err = new Error
                          err.customErrorMessage = 'Please select fax number type.'
                          throw err
                          return false
                fax_number :
                  allowNull : true
                  type : 'integer'
                  tryToCoerce : true
                  validation :
                    message : 'Please provide valid fax number. Sample: 09776546890.'
                    AND : [
                      {
                        minLength : 11
                        maxLength : 11
                      }
                    ]
            dob :
              allowNull : false
              type : 'string'
              validation :
                message : 'Please provide valid date of birth.'
                AND : [
                  {
                    minLength : 8
                    maxLength : 10240
                  }
                ]
            gender :
              allowNull : false
              type : 'string'
              validation :
                message : 'Please select a gender.'
                AND : [
                  {
                    minLength : 4
                    maxLength : 16
                  }
                ]
            nationality :
              allowNull : false
              type : 'string'
              validation :
                message : 'Please provide your valid nationality.'
                AND : [
                  {
                    minLength : 3
                    maxLength : 64
                  }
                ]
            contact_list :
              allowNull : false
              type : 'array'
              validation :
                custom :
                  message : 'Contact(s) required.'
                  params : [ '.' ]
                  fn : ( contact_list ) ->
                    if contact_list.length is 0
                      return false
                    return true
              def :
                contact_label :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Contact title required.'
                    AND : [
                      {
                        minLength : 3
                        maxLength : 128
                      }
                    ]
                contact_type :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Contact type required.'
                    AND : [
                      {
                        minLength : 3
                        maxLength : 32
                      }
                    ]
                    custom :
                      params : [ '.' ]
                      fn : ( contact_type ) ->
                        if contact_type in [ 'primary' , 'main' , 'work' , 'home' , 'present' ]
                          return true
                        else
                          err = new Error
                          err.customErrorMessage = 'Contact type required.'
                          throw err
                          return false
                contact_address :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Contact address required.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 256
                      }
                    ]
                contact_map_latitude :
                  allowNull : true
                  type : 'float'
                  tryToCoerce : true
                  validation :
                    message : 'Invalid latitude. (Sample: 1.0)'
                    AND : [
                      {
                        minLength : 3
                        maxLength : 32
                      }
                    ]
                contact_map_longitude :
                  allowNull : true
                  type : 'float'
                  tryToCoerce : true
                  validation :
                    message : 'Invalid longitude. (Sample: 1.0)'
                    AND : [
                      {
                        minLength : 3
                        maxLength : 32
                      }
                    ]
                contact_city :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Invalid contact city.'
                    AND : [
                      {
                        minLength : 2
                        maxLength : 32
                      }
                    ]
                contact_state :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Invalid contact state.'
                    AND : [
                      {
                        minLength : 2
                        maxLength : 32
                      }
                    ]
                contact_zip :
                  allowNull : false
                  type : 'integer'
                  tryToCoerce : true
                  validation :
                    message : 'Invalid contact zip code.'
                    AND : [
                      {
                        minLength : 3
                        maxLength : 32
                      }
                    ]
                contact_country :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Invalid contact country.'
                    AND : [
                      {
                        minLength : 3
                        maxLength : 32
                      }
                    ]
            profile_image :
              allowNull : true
              type : 'string'
              validation :
                message : 'Profile image required.'
                AND : [
                  {
                    minLength : 1
                    maxLength : 31457280
                  }
                ]
            biography :
              allowNull : true
              type : 'string'
              validation :
                message : 'Invalid biography.'
                AND : [
                  {
                    minLength : 1
                    maxLength : 2048
                  }
                ]
            degree_list :
              allowNull : true
              type : 'array'
              validation :
                custom :
                  message : 'At least "MBBS" degree is required.'
                  params : [ '^key_type' , '.' ]
                  fn : ( key_type , degree_list ) ->
                    if key_type is 'doctor'
                      fl = false
                      for item in degree_list
                        if item.degree_title.toLowerCase() is 'MBBS'.toLowerCase()
                          fl = true
                          break
                      return fl
                    else if key_type is 'patient'
                      if degree_list is null || ( typeof degree_list ) is 'undefined'
                        return true
                      err = new Error
                      err.customErrorMessage = 'Degree list is not applicable for \'patient\' type users.'
                      throw err
                      return false
              def :
                degree_title :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Invalid degree title.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 128
                      }
                    ]
                degree_institution :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Please select Institution Name.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 128
                      }
                    ]
                degree_details :
                  allowNull : true
                  type : 'string'
                  validation :
                    message : 'Invalid degree details.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 512
                      }
                    ]
                degree_year :
                  allowNull : false
                  type : 'integer'
                  tryToCoerce : true
                  validation :
                    message : 'Invalid degree year.'
                    AND : [
                      {
                        minLength : 4
                        maxLength : 4
                      }
                    ]
                    custom :
                      message : 'Degree year has to be a valid year between 1930 and 2030.'
                      params : [ '.' ]
                      fn : ( degree_year ) ->
                        if degree_year < 1930 || degree_year > 2030
                          return false
                        return true
            family_member_list :
              allowNull : true
              type : 'array'
              def :
                family_member_name :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Family member name is required.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 128
                      }
                    ]
                family_member_relation :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Family member relation is required.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 128
                      }
                    ]
                family_member_phone_number :
                  allowNull : true
                  type : 'integer'
                  tryToCoerce : true
                  validation :
                    message : 'Invalid family member phone number.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 32
                      }
                    ]
                family_member_email_id :
                  allowNull : true
                  type : 'string'
                  validation :
                    message : 'Invalid family member email address.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 128
                      }
                    ]
                    custom :
                      params : [ '.' ]
                      fn : ( family_member_email_id ) ->
                        if family_member_email_id is null || ( typeof family_member_email_id ) == 'undefined'
                          return true
                        emailRegex = /^([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$/i
                        res = emailRegex.test family_member_email_id
                        if res is false
                          err = new Error
                          err.customErrorMessage = 'Please type valid email address.'
                          throw err
                        return res
                family_member_address :
                  allowNull : true
                  type : 'string'
                  validation :
                    message : 'Invalid family member address.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 256
                      }
                    ]
            employment_details :
              allowNull : true
              type : 'array'
              def :
                employment_status :
                  allowNull : false
                  type : 'boolean'
                employment_title :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Employment title is required.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 128
                      }
                    ]
                current_position :
                  allowNull : true
                  type : 'string'
                  validation :
                    message : 'Employment current position is required.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 128
                      }
                    ]
                company_title :
                  allowNull : true
                  type : 'string'
                  validation :
                    message : 'Invalid employment company title.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 512
                      }
                    ]
                company_address :
                  allowNull : true
                  type : 'string'
                  validation :
                    message : 'Invalid employment company address.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 512
                      }
                    ]
                company_web_link :
                  allowNull : true
                  type : 'string'
                  validation :
                    message : 'Invalid employment company web link.'
                    AND : [
                      {
                        minLength : 10
                        maxLength : 512
                      }
                    ]
                company_thumb :
                  allowNull : true
                  type : 'string'
                  validation :
                    message : 'Invalid employment company thumbnail image.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 31457280
                      }
                    ]
                salary_range :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Employment salary range is required.'
                    AND : [
                      {
                        minLength : 3
                        maxLength : 32
                      }
                    ]
            certification_list :
              allowNull : true
              type : 'array'
              def :
                certification_title :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Certification title is required.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 128
                      }
                    ]
                certification_institution :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Certification institution is required.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 128
                      }
                    ]
                certification_details :
                  allowNull : true
                  type : 'string'
                  validation :
                    message : 'Invalid certification details.'
                    AND : [
                      {
                        minLength : 1
                        maxLength : 512
                      }
                    ]
                certification_year :
                  allowNull : false
                  type : 'integer'
                  validation :
                    message : 'Certification year is required.'
                    AND : [
                      {
                        minLength : 4
                        maxLength : 4
                      }
                    ]
            publication_list :
              allowNull : true
              type : 'array'
              def :
                publication_title :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Publication title is required.'
                    AND : [
                      {
                        minLength : 3
                        maxLength : 128
                      }
                    ]
                publication_thumbnail :
                  allowNull : true
                  type : 'string'
                  validation :
                    message : 'Invalid publication thumbnail image.'
                    AND : [
                      {
                        minLength : 10
                        maxLength : 10240
                      }
                    ]
                publication_url :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Publication URL is required.'
                    AND : [
                      {
                        minLength : 10
                        maxLength : 512
                      }
                    ]
            social_connection_list :
              allowNull : true
              type : 'array'
              def :
                social_connection_title :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Social connection title is required.'
                    AND : [
                      {
                        minLength : 3
                        maxLength : 128
                      }
                    ]
                social_connection_thumbnail :
                  allowNull : true
                  type : 'string'
                  validation :
                    message : 'Invalid social connection thumbnail image.'
                    AND : [
                      {
                        minLength : 10
                        maxLength : 10240
                      }
                    ]
                social_connection_url :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Social connection URL is required.'
                    AND : [
                      {
                        minLength : 10
                        maxLength : 512
                      }
                    ]
            website_list :
              allowNull : true
              type : 'array'
              def :
                website_title :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Website title is required.'
                    AND : [
                      {
                        minLength : 5
                        maxLength : 128
                      }
                    ]
                website_thumbnail :
                  allowNull : true
                  type : 'string'
                  validation :
                    message : 'Invalid website thumbnail image.'
                    AND : [
                      {
                        minLength : 10
                        maxLength : 10240
                      }
                    ]
                website_url :
                  allowNull : false
                  type : 'string'
                  validation :
                    message : 'Website URL is required.'
                    AND : [
                      {
                        minLength : 10
                        maxLength : 512
                      }
                    ]
        }

        signupData = {
          key_type : 'doctor'
          bmdc_reg_number : null
          bmdc_reg_type : null
          user_nid : null
          user_salutation : null
          first_name : null
          last_name : null
          password : null
          password_repeat : null
          email_id_list : null
          phone_number_list : null
          fax_number_list : null
          dob : null
          gender : null
          nationality : null
          contact_list : null
          profile_image : null
          biography : null
          degree_list : null
          family_member_list : null
          employment_details : null
          certification_list : null
          publication_list : null
          social_connection_list : null
          website_list : null
        }

        try
          userSignupSchema = new Schema userSignupJsonSignature
          response = userSignupSchema.extract signupData
        catch ex
          #console.log ex.message , ex.stack , 1002
          #console.log ex.errorDetails , 1000

    describe '#testSuit-16: Checks the html escape functionality for string type objects.' , =>

      it '1. Expect to properly escape strings due to "escapeHtml" flag set to true.' , =>
        addressJsonSignature = {
          type : 'object'
          allowNull : false
          map :
            address :
              type : 'string'
              escapeHtml : true
        }
        addressData = {
          address : '<b>asdf</b>'
        }

        addressSchema = new Schema addressJsonSignature
        data = addressSchema.extract addressData
        expect( data ).to.have.a.property( 'address' ).to.be.a( 'string' ).equals( '&lt;b&gt;asdf&lt;/b&gt;' )

      it '2. Expect to properly escape strings due to "alwaysEscapeHtml" flag set to true in options during initiation time.' , =>
        addressJsonSignature = {
          type : 'object'
          allowNull : false
          map :
            address :
              type : 'string'
        }
        addressData = {
          address : '<b>asdf</b>'
        }

        addressSchema = new Schema addressJsonSignature , { alwaysEscapeHtml : true }
        data = addressSchema.extract addressData
        expect( data ).to.have.a.property( 'address' ).to.be.a( 'string' ).equals( '&lt;b&gt;asdf&lt;/b&gt;' )

      it '3. Expect not to escape strings because neither "alwaysEscapeHtml" or "escapeHtml" flag is set to true.' , =>
        addressJsonSignature = {
          type : 'object'
          allowNull : false
          map :
            address :
              type : 'string'
        }
        addressData = {
          address : '<b>asdf</b>'
        }

        addressSchema = new Schema addressJsonSignature
        data = addressSchema.extract addressData
        expect( data ).to.have.a.property( 'address' ).to.be.a( 'string' ).equals( '<b>asdf</b>' )

    describe '#testSuite-17: Checks if the errorDetails of \'array\' type objects has correct properties.' , =>

      emailListJsonSignature = {
        type : 'object'
        allowNull : false
        map :
          emailList :
            allowNull : false
            type : 'array'
            def :
              emailType :
                allowNull : false
                type : 'string'
                validation :
                  message : 'Please provide a valid email type.'
                  AND : [
                    {
                      minLength : 10
                      maxLength : 20
                    }
                  ]
              emailAddress :
                allowNull : false
                type : 'string'
                validation :
                  message : 'Please provide a valid email address.'
                  AND : [
                    {
                      minLength : 9
                      maxLength : 20
                    }
                  ]
      }

      it '1. Checks for error in both index of array size of 2.' , =>

        _fn = () ->
          emailListSchema = new Schema emailListJsonSignature
          response = emailListSchema.extract data

        expect( _fn ).to.throw Error

        try
          data = {
            emailList : [
              {
                emailType : 'primaryasdasdsad'
                emailAddress : 'a@a.com'
              }
              {
                emailType : 'ab'
                emailAddress : 'e@e.aaaaaaaaa'
              }
            ]
          }
          emailListSchema = new Schema emailListJsonSignature
          response = emailListSchema.extract data
        catch ex
          errorDetails = ex.errorDetails
          expect( errorDetails ).to.have.a.property( 'emailList' ).to.be.a( 'array' )
          emailList = errorDetails.emailList
          expect( emailList ).to.have.length( 2 )
          firstEmailItem = emailList[ 0 ]
          expect( firstEmailItem ).to.be.a( 'object' )
          expect( firstEmailItem ).to.have.a.property( 'emailAddress' ).to.be.a( 'array' )
          emailAddress = firstEmailItem.emailAddress
          expect( emailAddress ).to.have.length( 2 )
          secondEmailItem = emailList[ 1 ]
          expect( secondEmailItem ).to.be.a( 'object' )
          expect( secondEmailItem ).to.have.a.property( 'emailType' ).to.be.a( 'array' )
          emailType = secondEmailItem.emailType
          expect( emailType ).to.have.length( 2 )

      it '2. Checks for error in first index of array size of 2.' , =>

        _fn = () ->
          emailListSchema = new Schema emailListJsonSignature
          response = emailListSchema.extract data

        expect( _fn ).to.throw Error

        try
          data = {
            emailList : [
              {
                emailType : 'sad'
                emailAddress : 'a@a.com'
              }
              {
                emailType : 'abasdasdasdasdc'
                emailAddress : 'e@e.zzzasdasdasdasd'
              }
            ]
          }
          emailListSchema = new Schema emailListJsonSignature
          response = emailListSchema.extract data
        catch ex
          errorDetails = ex.errorDetails
          expect( errorDetails ).to.have.a.property( 'emailList' ).to.be.a( 'array' )
          emailList = errorDetails.emailList
          expect( emailList ).to.have.length( 1 )
          firstEmailItem = emailList[ 0 ]
          expect( firstEmailItem ).to.be.a( 'object' )
          expect( firstEmailItem ).to.have.a.property( 'emailType' ).to.be.a( 'array' )
          expect( firstEmailItem ).to.have.a.property( 'emailAddress' ).to.be.a( 'array' )
          emailType = firstEmailItem.emailType
          expect( emailType ).to.have.length( 2 )
          emailAddress = firstEmailItem.emailAddress
          expect( emailAddress ).to.have.length( 2 )

      it '3. Checks for error in second index of array size of 2.' , =>

        _fn = () ->
          emailListSchema = new Schema emailListJsonSignature
          response = emailListSchema.extract data

        expect( _fn ).to.throw Error

        try
          data = {
            emailList : [
              {
                emailType : 'primaryasdasdsasda'
                emailAddress : 'a@a.asdasdasdasd'
              }
              {
                emailType : 'abc'
                emailAddress : 'e@e.z'
              }
            ]
          }
          emailListSchema = new Schema emailListJsonSignature
          response = emailListSchema.extract data
        catch ex
          errorDetails = ex.errorDetails
          expect( errorDetails ).to.have.a.property( 'emailList' ).to.be.a( 'array' )
          emailList = errorDetails.emailList
          expect( emailList ).to.have.length( 2 )
          firstEmailItem = emailList[ 0 ]
          expect( firstEmailItem ).to.be.a( 'object' )
          expect( firstEmailItem ).not.to.have.a.property( 'emailAddress' )
          expect( firstEmailItem ).not.to.have.a.property( 'emailType' )
          secondEmailItem = emailList[ 1 ]
          expect( secondEmailItem ).to.be.a( 'object' )
          expect( secondEmailItem ).to.have.a.property( 'emailType' ).to.be.a( 'array' )
          expect( secondEmailItem ).to.have.a.property( 'emailAddress' ).to.be.a( 'array' )
          emailType = secondEmailItem.emailType
          expect( emailType ).to.have.length( 2 )
          emailAddress = secondEmailItem.emailAddress
          expect( emailAddress ).to.have.length( 2 )
