{ expect } = require 'chai'

{ ConstantHelper } = require './../constant-helper'
{ Schema } = require './../schema'

describe 'Schema-Class-Skeleton' , =>

  _schemaJsonSignatureParameterChecker = ( schemaJsonSignatureParameter ) =>
    expect( schemaJsonSignatureParameter ).to.have.a.property( 'type' ).to.be.a( 'string' )
    expect( schemaJsonSignatureParameter ).to.have.a.property( 'allowNull' ).to.be.a( 'boolean' )
    expect( schemaJsonSignatureParameter ).to.have.a.property( 'validation' ).to.be.a( 'object' )
    if schemaJsonSignatureParameter.type is ConstantHelper.objectString
      expect( schemaJsonSignatureParameter ).to.have.a.property( 'map' ).to.be.a( 'object' )
      for key , value of schemaJsonSignatureParameter.map
        _schemaJsonSignatureParameterChecker value
    else
      expect( schemaJsonSignatureParameter ).not.to.have.a.property( 'map' )

  describe '#constructor' , =>

    describe '#testSuit-1' , =>

      it '1. Expect Schema to be a class.' , =>
        expect(Schema).to.be.a( 'function' )
        .with.a.property( 'constructor' )
        .which.is.a( 'function' )

      blankJsonSignatureSchema = new Schema {}
      schemaJsonSignature = blankJsonSignatureSchema.schemaJsonSignature

      it '2. Expect Schema class object to have "schemaOptions" property along with its own nested properties. This test is performed on empty json signature.' , =>
        expect( blankJsonSignatureSchema ).to.have.a.property( 'schemaOptions' )
        schemaOptions = blankJsonSignatureSchema.schemaOptions
        expect( schemaOptions ).to.be.a( 'object' )
        expect( schemaOptions ).to.have.a.property( 'suppressCyclicDataErrors' )
        expect( schemaOptions ).to.have.a.property( 'suppressCyclicDataErrors' ).to.be.a( 'boolean' )
        expect( schemaOptions ).to.have.a.property( 'suppressCyclicDataErrors' ).to.be.false
        expect( schemaOptions ).to.have.a.property( 'ignoreUnidentifiedData' )
        expect( schemaOptions ).to.have.a.property( 'ignoreUnidentifiedData' ).to.be.a( 'boolean' )
        expect( schemaOptions ).to.have.a.property( 'ignoreUnidentifiedData' ).to.be.false

      it '3. Expect Schema class object to have "schemaJsonSignature" property which should be a object. Details can be found on full-def.md file.' , =>
        expect( blankJsonSignatureSchema ).to.have.a.property( 'schemaJsonSignature' )
        expect( blankJsonSignatureSchema ).to.have.a.property( 'schemaJsonSignature' ).to.be.a( 'object' )

      it '4. Expect "schemaJsonSignature" object to have must required properties i.e. "type", "allowNull" and "validation" properties. Also checks for their property types. This assertion is performed recursively for each property in the map. Details can be found on full-def.md file.' , =>
        _schemaJsonSignatureParameterChecker schemaJsonSignature

    describe '#testSuit-2' , =>

      firstSchema = new Schema { validation : { OR : null , NOT : null , AND : [ { OR : null } , { NOT : null } , { AND : null } ] } }
      schemaJsonSignature = firstSchema.schemaJsonSignature

      it '1. Expect Schema class object to have proper initialized values for "validation" property.' , =>
        _schemaJsonSignatureParameterChecker schemaJsonSignature
        validationObj = schemaJsonSignature.validation
        expect( validationObj ).to.have.a.property( 'OR' ).to.be.a( 'array' )
        expect( validationObj ).to.have.a.property( 'NOT' ).to.be.a( 'object' )
        expect( validationObj ).to.have.a.property( 'AND' ).to.be.a( 'array' )
        andObj = schemaJsonSignature.validation.AND
        expect( andObj[ 0 ] ).to.have.a.property( 'OR' ).to.be.a( 'array' )
        expect( andObj[ 1 ] ).to.have.a.property( 'NOT' ).to.be.a( 'object' )
        expect( andObj[ 2 ] ).to.have.a.property( 'AND' ).to.be.a( 'array' )

    describe '#testSuit-3' , =>

      firstSchema = new Schema { message : 'sample error message outside validation object' , minLength : 10 }
      schemaJsonSignature = firstSchema.schemaJsonSignature
      it '1. Expect Schema class object not to have "validation" properties outside validation object.' , =>
        _schemaJsonSignatureParameterChecker schemaJsonSignature
        expect( schemaJsonSignature ).not.to.have.a.property( 'message' )
        expect( schemaJsonSignature ).not.to.have.a.property( 'minLength' )
        validationObj = schemaJsonSignature.validation
        expect( validationObj ).not.to.have.a.property( 'message' )
        expect( validationObj ).not.to.have.a.property( 'minLength' )
        expect( validationObj ).to.have.a.property( 'AND' ).to.be.a( 'array' )
        expect( validationObj.AND ).to.contain( { 'minLength' : 10 } )
        expect( validationObj.AND ).to.contain( { message : 'sample error message outside validation object' } )

  describe '#merge' , =>

    describe '#testSuit-1' , =>

      it '1. Expect Schema to have a static method called merge().' , =>
        expect( Schema.merge ).to.be.a( 'function' )

  describe '#isValid' , =>

    describe '#testSuit-1' , =>

      it '1. Expect Schema to have a method called isValid().' , =>
        expect( new Schema ).to.have.a.property( 'isValid' ).which.is.a( 'function' )

  describe '#extract' , =>

    describe '#testSuit-1' , =>

      it '1. Expect Schema to have a method called extract().' , =>
        expect( new Schema ).to.have.a.property( 'extract' ).which.is.a( 'function' )

    describe '#testSuit-2 : checks custom validation function definitions.' , =>

      it '1. Expect merge() to throw error because of custom validation property doesnt have a comparator function.' , =>
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
                }
              }
            }
          }
        }
        _fn = () =>
          userDataSchema = new Schema userDataSchemaJson
        expect( _fn ).to.throw( Error )
        try
          userDataSchema = new Schema userDataSchemaJson
        catch ex
          expect( ex.errorDetails ).to.have.string 'No function defined for custom validation property.'

      it '2. Expect merge() to throw error because of custom validation property doesn\'t have a params property.' , =>
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
                  fn : ( password , repeatedPassword ) -> return password is repeatedPassword
                }
              }
            }
          }
        }
        _fn = () =>
          userDataSchema = new Schema userDataSchemaJson
        expect( _fn ).to.throw( Error )
        try
          userDataSchema = new Schema userDataSchemaJson
        catch ex
          expect( ex.errorDetails ).to.have.string 'No params defined for custom validation property.'
