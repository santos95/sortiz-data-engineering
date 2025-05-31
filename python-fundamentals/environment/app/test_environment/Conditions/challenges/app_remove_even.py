def remove_even(numbers):
    for num in numbers:
        if num % 2 == 0:
            print(num)
            numbers.remove(num)


values = [1, 2, 3, 4, 5, 10, 20]
remove_even(values)

# this version skip some values because is iterating on a list that has been modified during making skiping some values 
# for this example skip 20 because the index value of 20 when removing a value change.
print(values)

# fixed - get a copy to iterate
values = [1, 2, 3, 4, 5, 20]
print("size of values: ", len(values))

def remove_even_fix(numbers):
    for i, num in enumerate(values):
        if num % 2 == 0:
            print(num)
            numbers.pop(i)

remove_even_fix(values)
print(values)