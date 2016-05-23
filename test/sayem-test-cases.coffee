{ expect } = require 'chai'

{ ConstantHelper } = require './../constant-helper'
{ Schema } = require './../schema'


passwordStrengthCheckingFunction = ( password ) -> 'acceptable'

describe 'Sayem Test Cases' , ->

  it 'Scenario One', ->

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
              mutationFn : ( value )-> new Date value

            nationalIdCardNumber :
              type : 'string'
              allowNull : false
              validation :
                minLength : 20
                maxLength : 32

            # emailList :
            #   type : 'array'
            #   allowNull : false
            #   def :
            #     address :
            #       type : 'string'
            #       validation :
            #         custom :
            #           params : [ '.' ]
            #           fn : ( value ) ->
            #             emailRegex = /^([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$/i
            #             return emailRegex.test value
            #     isPrimary :
            #       type : 'boolean'
            #       allowNull : false
            #       validation :
            #         custom :
            #           params : [ '^^' ]
            #           fn : ( value ) ->
            #             cn = 0
            #             for item in value
            #               cn++ if item.isPrimary is true
            #             return true if cn is 1
            #             return false

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

    try
      $user = new Schema userRegistrationSchemaJson
      userData = $user.extract exampleUser
      console.log exampleUser
      console.log userData
    catch ex
      console.log ex.errorDetails
