library dirty_checking_change_detector_dynamic;

import 'change_detection.dart';
export 'change_detection.dart' show
    FieldGetterFactory;

/**
 * We are using mirrors, but there is no need to import anything.
 */
@MirrorsUsed(targets: const [ DynamicFieldGetterFactory ], metaTargets: const [] )
import 'dart:mirrors';

class DynamicFieldGetterFactory implements FieldGetterFactory {
  FieldGetter getter(Object object, String name) {
    Symbol symbol = new Symbol(name);
    InstanceMirror instanceMirror = reflect(object);
    return (Object object) => instanceMirror.getField(symbol).reflectee;
  }
}
