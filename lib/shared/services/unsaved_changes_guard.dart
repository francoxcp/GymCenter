/// Guard global que permite a cualquier pantalla interceptar la navegación
/// del navbar antes de que se ejecute [context.go()].
///
/// Uso:
///   - La pantalla llama a [register] con un callback que devuelve `true`
///     si se puede navegar (el usuario confirmó descartar cambios).
///   - La pantalla llama a [unregister] en su [dispose].
///   - El navbar llama a [canNavigate] antes de hacer [context.go()].
class UnsavedChangesGuard {
  UnsavedChangesGuard._();

  static Future<bool> Function()? _callback;

  /// Registra un callback que se invoca cuando el usuario intenta navegar
  /// a través del navbar. Devuelve `true` si la navegación puede proceder.
  static void register(Future<bool> Function() callback) {
    _callback = callback;
  }

  /// Elimina el callback registrado (llamar en [dispose]).
  static void unregister() {
    _callback = null;
  }

  /// Devuelve `true` si no hay guard activo, o si el callback confirma
  /// que se puede navegar.
  static Future<bool> canNavigate() async {
    if (_callback == null) return true;
    return await _callback!();
  }
}
