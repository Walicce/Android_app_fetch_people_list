import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart' as path_provider;

class Person {
  String id;
  String firstName;
  String lastName;
  String city;
  String phoneNumber;
  String avatar;

  Person({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.city,
    required this.phoneNumber,
    required this.avatar,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'city': city,
      'phoneNumber': phoneNumber,
      'avatar': avatar,
    };
  }
}

class NetworkService {
  Future<Person> fetchRandomPerson() async {
    final response = await http.get(Uri.parse('https://randomuser.me/api/'));
    if (response.statusCode == 200) {
      final jsonMap = json.decode(response.body);
      final results = jsonMap['results'][0];
      final personId = results['login']['uuid'];
      return Person(
        id: personId,
        firstName: results['name']['first'],
        lastName: results['name']['last'],
        city: results['location']['city'],
        phoneNumber: results['phone'],
        avatar: results['picture']['large'],
      );
    } else {
      throw Exception('Failed to fetch person');
    }
  }
}

class FileService {
  Future<File> getLocalFile() async {
    Directory directory = await path_provider.getApplicationDocumentsDirectory();
    final path = directory.path;
    return File('$path + people.json');
  }

  Future<void> writeToFile(List<Person> persons) async {
    File file = await getLocalFile();
    final jsonList = persons.map((person) => personToJson(person)).toList();
    final jsonString = json.encode(jsonList);
    await file.writeAsString(jsonString);
  }

  Future<List<Person>> readFromFile() async {
    try {
      File file = await getLocalFile();
      final jsonString = await file.readAsString();
      final jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList.map((json) => personFromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Map<String, dynamic> personToJson(Person person) {
    return {
      'id': person.id,
      'firstName': person.firstName,
      'lastName': person.lastName,
      'city': person.city,
      'phoneNumber': person.phoneNumber,
      'avatar': person.avatar,
    };
  }

  Person personFromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      city: json['city'],
      phoneNumber: json['phoneNumber'],
      avatar: json['avatar'],
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  NetworkService networkService = NetworkService();
  FileService fileService = FileService();

  List<Person> persons = [];
  List<Person> offlinePersons = [];

  int totalPeople = 10;
  int peopleToShow = 5;

  bool isOnline = true;

  Future<void> fetchPeople() async {
    persons.clear();
    for (int i = 0; i < totalPeople; i++) {
      final person = await networkService.fetchRandomPerson();
      persons.add(person);
    }
    setState(() {});
  }

  Future<void> loadMorePeople() async {
    final newPersons = <Person>[];
    for (int i = 0; i < peopleToShow; i++) {
      final person = await networkService.fetchRandomPerson();
      newPersons.add(person);
    }
    setState(() {
      persons.addAll(newPersons);
    });
  }

  Future<void> writePersonsToFile(int numberOfPeople) async {
    await fileService.writeToFile(persons.take(numberOfPeople).toList());
  }

  Future<void> readPersonsFromFile(int numberOfPeople) async {
    final loadedPersons = await fileService.readFromFile();
    setState(() {
      offlinePersons = loadedPersons.take(numberOfPeople).toList();
    });
  }

  void toggleMode() {
    setState(() {
      isOnline = !isOnline;
    });
  }

  void editPersonData(Person person) {
    showDialog(
      context: context,
      builder: (context) {
        String newFirstName = person.firstName;
        String newLastName = person.lastName;
        String newCity = person.city;
        String newPhoneNumber = person.phoneNumber;

        return AlertDialog(
          title: const Text('Edit Person'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: person.firstName,
                decoration: const InputDecoration(labelText: 'First Name'),
                onChanged: (value) {
                  newFirstName = value;
                },
              ),
              TextFormField(
                initialValue: person.lastName,
                decoration: const InputDecoration(labelText: 'Last Name'),
                onChanged: (value) {
                  newLastName = value;
                },
              ),
              TextFormField(
                initialValue: person.city,
                decoration: const InputDecoration(labelText: 'City'),
                onChanged: (value) {
                  newCity = value;
                },
              ),
              TextFormField(
                initialValue: person.phoneNumber,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                onChanged: (value) {
                  newPhoneNumber = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            if (isOnline) ...[
              TextButton(
                onPressed: () {
                  setState(() {
                    person.firstName = newFirstName;
                    person.lastName = newLastName;
                    person.city = newCity;
                    person.phoneNumber = newPhoneNumber;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ] else ...[
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Offline Editing'),
                        content: const Text('Editing is not available in offline mode.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text('Save'),
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    fetchPeople();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('People randomizer'),
          backgroundColor: Colors.blue, // Change the app bar color
        ),
        backgroundColor: Colors.blueGrey, // Change the background color
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Online Mode',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Switch(
                      value: isOnline,
                      onChanged: (value) {
                        setState(() {
                          isOnline = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isOnline) ...[
                  Row(
                    children: [
                      const Text('Total People to load: '),
                      DropdownButton<int>(
                        value: totalPeople,
                        onChanged: (value) {
                          setState(() {
                            totalPeople = value!;
                          });
                        },
                        items: [5, 10, 15, 20]
                            .map((value) => DropdownMenuItem<int>(
                          value: value,
                          child: Text(value.toString()),
                        ))
                            .toList(),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('People to Show offline: '),
                      DropdownButton<int>(
                        value: peopleToShow,
                        onChanged: (value) {
                          setState(() {
                            peopleToShow = value!;
                          });
                        },
                        items: [1, 3, 5, 10, 20, 50]
                            .map((value) => DropdownMenuItem<int>(
                          value: value,
                          child: Text(value.toString()),
                        ))
                            .toList(),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: loadMorePeople,
                    child: const Text('Load More'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      writePersonsToFile(peopleToShow);
                    },
                    child: const Text('Save to File'),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () {
                      readPersonsFromFile(peopleToShow);
                    },
                    child: const Text('Load from File'),
                  ),
                ],
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: isOnline ? persons.length : offlinePersons.length,
                  itemBuilder: (context, index) {
                    final person =
                    isOnline ? persons[index] : offlinePersons[index];
                    return Card(
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(person.avatar),
                        ),
                        title: Text(
                          '${person.firstName} ${person.lastName}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('City: ${person.city}'),
                            Text('Phone: ${person.phoneNumber}'),
                          ],
                        ),
                        onTap: () {
                          if (!isOnline) {
                            editPersonData(person);
                          }
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: MyApp(),
    theme: ThemeData(
      primaryColor: Colors.blue,
      colorScheme:
      ColorScheme.fromSwatch().copyWith(secondary: Colors.blueAccent),
      // Change the accent color
    ),
  ));
}