import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class UserService {
  static String get baseUrl {
  if (kIsWeb) {
    return 'http://localhost:9000/api/users';
  } 
  else if (!kIsWeb && Platform.isAndroid) {
    return 'http://10.0.2.2:9000/api/users';
  } 
  else {
    return 'http://localhost:9000/api/users';
  }
}

  static Future<List<User>> getUsers() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Error en carregar usuaris');
    }
  }

  static Future<User> createUser(User user) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al crear usuari: ${response.statusCode}');
    }
  }

  static Future<User> getUserById(String id) async {
    print("Obteniendo usuario con ID: $id");
    final response = await http.get(Uri.parse('$baseUrl/$id'));

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      print("Datos recibidos del usuario: $userData");
      return User.fromJson(userData);
    } else {
      print("Error al obtener usuario. Código: ${response.statusCode}, Respuesta: ${response.body}");
      throw Exception("Error a l'obtenir usuari: ${response.statusCode}");
    }
  }

  static Future<User> updateUser(String id, User user) async {
    print("Actualizando usuario con ID: $id");
    print("Datos enviados: ${user.toJson()}");
    
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print("Respuesta actualización: $responseData");
      
      // La respuesta es solo una confirmación, no los datos actualizados
      // Debemos obtener el usuario actualizado con una segunda llamada
      try {
        // Crear un nuevo usuario con los datos que enviamos más el ID
        final updatedUser = User(
          id: id,
          name: user.name,
          age: user.age,
          email: user.email,
          password: user.password
        );
        
        // También podemos intentar obtener los datos más recientes
        // Pero usamos los locales en caso de error
        try {
          final refreshedUser = await getUserById(id);
          return refreshedUser;
        } catch (e) {
          print("No se pudo obtener usuario actualizado: $e");
          return updatedUser;
        }
      } catch (e) {
        print("Error al procesar respuesta: $e");
        throw Exception('Error al procesar datos del usuario');
      }
    } else {
      print("Error al actualizar usuario. Código: ${response.statusCode}, Respuesta: ${response.body}");
      throw Exception('Error actualitzant usuari: ${response.statusCode}');
    }
  }

  static Future<bool> deleteUser(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Error eliminant usuari: ${response.statusCode}');
    }
  }
}
