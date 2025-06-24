# for loops - controlled flow iteration - for loops in which the numbers of repititions is knowded 
yakuza_games = ['YAKUZA 0', 'YAKUZA KIWAMI', 'YAKUZA KIWAMI 2', 'YAKUZA 3', 'YAKUZA 4', 'YAKUZA 5', 'YAKUZA 6', 'YAKUZA LIKE A DRAGON', 'LIKE A DRAGON INFINITE WEALTH']


print('range type ', type(range(len(yakuza_games))))

# using the range function we get a sequence of index values - by default with one parameter n = 5 - iterates over 0 - 4, if we pass two range(1, 5) - iterates over 1 - 4 - in python 3 range return an range object
for i in range(len(yakuza_games)):
    print(yakuza_games[i])

# we can get the index and the value of the elements of the list 
for i, game in enumerate(yakuza_games):
    print(i, game)

# we can use directly the list to iterate
for game in yakuza_games:
    print(game)

# while loops - are used in scenarios where we dont know how many times we have to iterate to resolve the problem - are commonly used to iterate over a condition - when the condition is true iterates but if is false stop 
# is not controlled flow iteration 

squares = ['yellow', 'yellow','yellow', 'orange', 'yellow']


i = 0 
yellow_squares = []

# copy the values different from orange - once orange is found the loops end 
while squares[i] != 'orange':
    
    yellow_squares.append(squares[i])
    i += 1

print(yellow_squares)


# iterate through list dates and stop at the year 1973, then print out the number of iterations
years = [2001, 2022, 2003, 2014, 1973, 2005]

i = 0
year = years[i]

while (year != 1973): 
    print(year)
    i += 1
    year = years[i]

print(f"to get out of the loop was necessary {i} iterations")


# Write a while loop to copy the strings 'orange' of the list squares to the list new_squares. Stop and exit the loop if the value on the list is not 'orange':
print(' Write a while loop to copy the strings orange of the list squares to the list new_squares. Stop and exit the loop if the value on the list is not orange:')
squares = ['orange', 'orange', 'blue', 'orange', 'yellow', 'orange', 'red', 'orange']

new_squares = []
i = 0 

while squares[i] == 'orange':
    new_squares.append(squares[i])
    i += 1

for square in new_squares:
    print(square)

# copy all the orange blocks to new squares
print('copy all the orange blocks to new squares')
for square in squares:
    if square == 'orange':
        new_squares.append(square)
    

for square in new_squares:
    print(square)


