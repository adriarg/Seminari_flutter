import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/UserService.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final authService = AuthService();
      final result = await authService.login(email, password);

      if (result.containsKey('error')) {
        _setError(result['error']);
        _setLoading(false);
        return false;
      } else {
        // Extraer ID del usuario de la respuesta
        String? userId; 
        
        // Intentar obtener el ID con diferentes claves posibles
        if (result.containsKey('_id')) {
          userId = result['_id'];
        } else if (result.containsKey('id')) {
          userId = result['id'];
        } else if (result.containsKey('user') && result['user'] is Map) {
          final userMap = result['user'] as Map;
          userId = userMap['_id'] ?? userMap['id'];
        }
        
        print("ID de usuario extraído: $userId");
        
        if (userId == null) {
          _setError('No se pudo obtener el ID del usuario');
          _setLoading(false);
          return false;
        }
        
        // Siempre crear un usuario básico con la información que tenemos
        _currentUser = User(
          id: userId,
          name: result['name'] ?? 'Usuario',
          age: result['age'] ?? 0,
          email: email,
          password: password,
        );
        
        _isAuthenticated = true;
        notifyListeners();
        
        // Después de autenticar, intentar obtener datos completos
        try {
          final userData = await UserService.getUserById(userId);
          print("Datos completos obtenidos: ${userData.name}, ${userData.email}, ${userData.age}");
          
          // Actualizar con los datos completos pero manteniendo la contraseña
          _currentUser = User(
            id: userData.id,
            name: userData.name,
            age: userData.age,
            email: userData.email,
            password: password, // Mantener la contraseña que se usó para iniciar sesión
          );
          
          notifyListeners();
        } catch (e) {
          print("Error al obtener datos completos: $e");
          // No hacemos nada aquí, ya tenemos un usuario básico
        }
        
        _setLoading(false);
        return true;
      }
    } catch (e) {
      _setError('Error en iniciar sesión: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      final authService = AuthService();
      authService.logout();
      _currentUser = null;
      _isAuthenticated = false;
    } catch (e) {
      _setError('Error al cerrar sesión: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateUserProfile(String userId, String name, int age, String email) async {
    _setLoading(true);
    _setError(null);

    try {
      if (_currentUser == null) {
        _setError('No hay usuario autenticado');
        _setLoading(false);
        return false;
      }

      // Guardar el ID original por si se pierde en el proceso
      final originalId = userId;

      // Creamos un nuevo objeto User con los datos actualizados pero manteniendo la contraseña actual
      final updatedUser = User(
        id: userId,
        name: name,
        age: age,
        email: email,
        password: _currentUser!.password, // Mantenemos la contraseña actual
      );

      print("Actualizando usuario: $userId");
      print("Datos: Nombre=$name, Edad=$age, Email=$email");

      final result = await UserService.updateUser(userId, updatedUser);
      
      // Asegurarnos de que el ID se mantenga
      if (result.id == null && originalId.isNotEmpty) {
        // Si perdimos el ID en el proceso, restaurarlo
        final fixedUser = User(
          id: originalId,
          name: result.name,
          age: result.age,
          email: result.email,
          password: result.password
        );
        _currentUser = fixedUser;
      } else {
        _currentUser = result;
      }
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      print("Error al actualizar perfil: $e");
      _setError('Error al actualizar el perfil: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> changePassword(String userId, String currentPassword, String newPassword) async {
    _setLoading(true);
    _setError(null);

    try {
      if (_currentUser == null) {
        _setError('No hay usuario autenticado');
        _setLoading(false);
        return false;
      }

      // Verificar que la contraseña actual sea correcta
      if (_currentUser?.password != currentPassword) {
        _setError('La contraseña actual es incorrecta');
        _setLoading(false);
        return false;
      }

      // Guardar el ID original por si se pierde
      final originalId = userId;

      // Crear un usuario actualizado con la nueva contraseña
      final updatedUser = User(
        id: userId,
        name: _currentUser!.name,
        age: _currentUser!.age,
        email: _currentUser!.email,
        password: newPassword,
      );

      print("Cambiando contraseña para usuario: $userId");

      final result = await UserService.updateUser(userId, updatedUser);
      
      // Asegurarnos de que el ID se mantenga
      if (result.id == null && originalId.isNotEmpty) {
        // Si perdimos el ID en el proceso, restaurarlo
        final fixedUser = User(
          id: originalId,
          name: result.name,
          age: result.age,
          email: result.email,
          password: newPassword // Usar la nueva contraseña
        );
        _currentUser = fixedUser;
      } else {
        _currentUser = result;
      }
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      print("Error al cambiar contraseña: $e");
      _setError('Error al cambiar la contraseña: $e');
      _setLoading(false);
      return false;
    }
  }

  // Método para actualizar el usuario actual directamente sin llamar al backend
  void updateCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }
} 