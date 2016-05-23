{ expect } = require 'chai'

{ ConstantHelper } = require './../constant-helper'
{ Schema } = require './../schema'

describe 'Class Schema' , =>

  describe 'Debugging-Test-Suit-Ijaz' , =>

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
