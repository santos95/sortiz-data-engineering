users = {
    "alice": "password123",
    "bob": "qwerty"
}

def login(username, password):
    if username in users:
        if users[username] == password:
            print("Login successful!")
        else:
            print("Incorrect password.")
    else:
        print("Username not found.")

login('alice', 'password123')
login('alice', 'password12')
login('peter', 'password123')