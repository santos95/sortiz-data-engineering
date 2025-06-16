def g(c):
    return sum(c)

c = [1, 2, 3, 4, 5]

if sum(c) == g(c):
    print('Correct')
else:
    print('Error')