

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

# validateAs
these are some predefined rules that we will have built into the system

* full-name
* email

# common traits

allowNull

minLength
maxLength

minValue
maxValue

matchesExactly
startsWith
endsWith
contains
doesNotContain

# the 'validation' property
the validation property allows for custom rules, complete with three boolean logic gates. AND, OR, NOT.
there is a 'message' property that allows for a custom message to be shown if the validation fails