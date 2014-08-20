part of dart2es6.visitor;

/**
 * Identifiers that will always be replaced by the JS equivalent
 */
Map<String, String> GLOBAL_REPLACE = {
    'print': 'console.log',
};

/**
 * Dictionary of types to a map of <Dart field name, JS equivalent name>.
 * JS name should be left as empty string if there is no equivalent and should error
 * Fields/methods not listed here will not be replaced and be left as-is in JS.
 */
Map<Type, Map<String, String>> FIELD_REPLACE = {
    List: {
        'add': 'push',
    }
};

/**
 * returns true if B implements A
 * This is used to check if B, found in code, has a field/method of A that should be replaced.
 *
 * DartType is a weird class used by analyzer
 * TODO: un-hack it and compare types instead of the string repr of type & support subclasses
 */
_sameType(DartType a, Type b) {
  return a.displayName.contains(b.toString());
}

/**
 * replaces field & method names for Dart classes, such as .add => .push for Lists
 *
 * [target] is type of the object, [field] is the field that the return value will be the JS
 * equivalent of. Most cases the return value will be the field that was passed in, and it will
 * only be different when the field for the type has an alternative name in JS.
 */
String _replacedField(DartType target, String field) {
  var key = FIELD_REPLACE.keys.where((t) => _sameType(target, t));
  if (key.isEmpty) return field;
  assert(key.length == 1);
  var replace = FIELD_REPLACE[key.first][field];
  if (replace == "") throw "Unsupported field/method: ${key.first}.$field.";
  return replace == null ? field : replace;
}

/**
 * TODO
 * This function should check if a function or variable declared in the global scope
 * shadows any global builtins or other already declared global variables to help throw a
 * warning to the user.
 */
_doesNotShadow(String name) => !GLOBAL_REPLACE.keys.contains(name);
