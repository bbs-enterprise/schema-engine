
{Schema} = require './schema-engine.coffee'

# definition Part

userCommonSchema = new Schema({
  name: {type: 'string', validation: {
    message: 'Invalid Name',
    AND: [
      {minLength: 3, maxLength: 256},
      {
        NOT: {
          OR: [
            {contains: 'fuck'},
            {contains: 'shit'},
            {contains: 'whore'}
          ]
        }
      }
    ]
  }},
  email: {type: 'string', minLength: 3, maxLength: 256, validateAs: 'email'}
})

userFormInputSchema = Schema.merge(userCommonSchema, new Schema({
   password: {type: 'string', minLength: 8, maxLength: 256}
}))

userDbSchema = Schema.merge(userCommonSchema, new Schema({
  passwordHash: {type: 'string', minLength: 8, maxLength: 256}
}))

# usage part

formData = {
  name: 'test1'
  email: 'test1@example.com'
  password: '12345678'
}

if userFormInputSchema.isValid formData
  userData = userCommonSchema.extract formData
  userData.passwordHash = (require 'crypto').createHash('sha256').update(formData.password, 'utf8').digest('base64')
  if userDbSchema.isValid userData
    # do db operations and such..
    console.log 'STD OUTPUT: valid userDbSchema data'
  else
    console.log 'STD OUTPUT: invalid userDbSchema data'
else
  # reply with error and such..
  console.log 'STD OUTPUT: invalid userFormInputSchema data'


formData = {
  name: 'teshitst2'
  email: 'test2@example.com'
  password: '12345678'
}

if userFormInputSchema.isValid formData
  userData = userCommonSchema.extract formData
  userData.passwordHash = (require 'crypto').createHash('sha256').update(formData.password, 'utf8').digest('base64')
  if userDbSchema.isValid userData
    # do db operations and such..
    console.log 'STD OUTPUT: valid userDbSchema data'
  else
    console.log 'STD OUTPUT: invalid userDbSchema data'
else
  # reply with error and such..
  console.log 'STD OUTPUT: invalid userFormInputSchema data'


