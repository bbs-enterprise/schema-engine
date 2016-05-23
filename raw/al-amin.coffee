

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

      it.only '2. Test for data extraction from given data.' , =>
        _fn = () ->
          userDataSchema.extract exampleUser
        expect( _fn ).not.to.throw Error
        try
          data = userDataSchema.extract exampleUser
          console.log data
        catch ex
          console.log ex.errorDetails









    describe '#First-Test-Case' , =>

      it '1. Testing sample object property.' ,  =>
        obj = {
          name : 'John'
        }
        expect( obj ).to.have.a.property( 'name' )

    describe '#Second-Test-Case' , =>
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
              minLength : 10
              maxLength : 256
            }
          }
        }
      }

      userData = {
        firstName : 'John'
        lastName : 'Doe'
      }

      it '1. Expect extract() to return proper value object.' , =>
        userDataSchema = new Schema userDataSchemaJson
        _fn = () ->
          data = userDataSchema.extract userData
        expect( _fn ).to.throw Error
        try
          data = userDataSchema.extract userData
        catch ex
          expect( ex ).to.have.a.property( 'errorDetails' )
          errorDetails = ex.errorDetails
          #console.log errorDetails
          expect( errorDetails ).to.have.a.property( 'lastName' ).to.have.a.property( 'errorList' ).to.be.a( 'array' )
          errorList = errorDetails.lastName.errorList
          expect( errorList ).to.have.length( 2 )
          expect( errorList ).to.include( 'Minimum length not satisfied of lastName. Expected length of at least 10 and received a length of 3' )
          expect( errorList ).to.include( 'Validation error in "lastName" property (custom error message not provided in schema signature).' )

        #console.log data
        expect( data ).to.have.a.property( 'firstName' )
        expect( data ).to.have.a.property( 'firstName' ).to.equal( 'Mr. John' )
        expect( data ).to.have.a.property( 'lastName' )
        expect( data ).to.have.a.property( 'lastName' ).to.equal( 'Doe' )
