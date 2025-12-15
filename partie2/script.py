import yaml

users = []
with open('students.txt') as f:
    for line in f:
        line = line.strip()
        if not line:  # ignorer lignes vides
            continue
        username, password, fullname, phone, email, shell = line.split(";")
        users.append({
            'username': username,
            'password': password,
            'fullname': fullname,
            'phone': phone,
            'email': email,
            'shell': shell
        })

data = {'users': users}

with open('users.yml', 'w') as outfile:
    yaml.dump(data, outfile, default_flow_style=False, sort_keys=False)

print("users.yml généré avec succès !")
