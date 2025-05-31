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



