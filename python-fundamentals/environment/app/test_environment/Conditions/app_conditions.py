# boolean values - true, false
# so the comparison using comparison operators and logical operators get as result boolean values 

# if statement example

#age = 19
age = 18

# contions - compare two values or operands and get a boolean value, use comparision operators  == (equal), (!=) Inequality, >, < greater than and less than, <=, >= less than or equal and greater than or equal
print(age > 18)

# we can also compare strings, letters ans signs - basic on asci decimal values 
print("A > B: ", 'A' > 'B' )

# in this case take precedence the first letter so compare the value of A and B - When comparing strings python is case sensitive
print("AB > BA: ",  'AB' > 'BA' )

# 
print("Hello there is equal to hello there: ", 'Hello there' == 'hello there')
# 
print("hello there is equal to hello there: ", 'hello there' == 'hello there')

isMayor = age > 18
print(not(isMayor))

# branching - allow to run different statements base on inputs - which mean depending of inputs we can decide what our app will do - for example enter to a concert if the age greater than 18
if age > 18:
    print("You can enter to the ACDC concert")
elif age == 18: 
    print("You can enter to rush concert")
else:
    print("You can enter to the justin concert")

print("Move on")

# Condition statement example

album_year = 1983
#album_year = 1970

if album_year > 1980:
    print("Album year is greater than 1980")
else:
    print("less than 1980")

print('do something..')

# logical operators - and, or and not - are used to compare more that one condition at the same time
# and - are true when all the conditions are true 
# or - is true when at lease one condition is true
# not - true when false and false when true
# Condition statement example - conditions is true if the value is between 1980 and 1989

album_year = 1980

if(album_year > 1979) and (album_year < 1990):
    print ("Album year was in between 1980 and 1989")
    
print("")
print("Do Stuff..")

# Condition statement example - check if the album is made early of the 80 or after the 89 
# condition is true if the value is less than 1980 and greater than 1989

album_year = 1990

if(album_year < 1980) or (album_year > 1989):
    print ("Album was not made in the 1980's")
else:
    print("The Album was made in the 1980's ")



# the not statement to check if the statment is false
album_year = 1983    

if not (album_year == 1984):
    print("Album year is not 1984")


# Write your code below and press Shift+Enter to execute
name = 'Usain Bolt'
sport = 'Athletics'
achievements = 8

if sport != 'Soccer' and achievements < 10:
    print(f"{name} meets the criteria! plays {sport} and has only {achievements} achievements")
else:
    print(f"{name} does not meet the criteria")