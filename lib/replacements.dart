part of dart2es6.visitor;

Map<String, String> GLOBAL_REPLACE = {
    'print': 'console.log',
};

Map<Type, Map<String, String>> FIELD_REPLACE = {
    List: {
        'add': 'push',
    }
};


/**
 * returns true if B implements A
 */
_sameType(DartType a, Type b) { // TODO: un-hack this
  return a.displayName.contains(b.toString());
}

/**
 * replaces field & method names for Dart classes, such as .add => .push for Lists
 */
String _replacedField(DartType target, String field) {
  var key = FIELD_REPLACE.keys.where((t) => _sameType(target, t));
  if (key.isEmpty) return field;
  assert(key.length == 1);
  var replace = FIELD_REPLACE[key.first][field];
  if (replace == "") throw "Unsupported field/method: ${key.first}.$field.";
  return replace == null ? field : replace;
}
