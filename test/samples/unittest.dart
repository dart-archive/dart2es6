import '../annotations.dart';

globalFunction() => print('globalFunction called');
globalFunctionParam(param) => print('globalFunctionParam called with ' + param);

@describe
class Operators {
  @it
  shouldAdd() => 1 + 2;
  @it
  shouldFollowParenthesizedPrecedence() => (2 + 2) * 3;
  @it
  shouldDivideIntegers() => 20 / 4;
  @it
  shouldHandleFloatingPointDivisionOfIntegers() => 20 / 3;
  @it
  shouldHandleModulus() => 20 % 13;
  @it
  shouldConcatenateStringsImplicitly() => "return" + "A" "String";
}

@describe
class Methods1 {
  @it
  shouldAcceptRequiredParameters(a, b) {
    return a + b;
  }
  @it
  shouldAcceptPositionalParameters([something]) {
    return something;
  }
  @it
  shouldAcceptPositionalParametersWithDefaultValues([something = 1+1]) {
    return something;
  }
}

@describe
class Methods2 {
  @it
  shouldCallFunctions() {
    globalFunction();
  }
}

@describe
class Constructors1 {
  var field1;
  var field2 = 2;
  var field3 = globalFunction() + 2;
  Constructors1();
  @it
  shouldSetDeclaredFieldsToNullByDefault() => field1;
  @it
  shouldSetFieldsWithDefaultValue() => field2;
  @it
  shouldCalculateFieldDefaultValues() => field3;
}

@describe
class Constructors2 {
  @it
  shouldInitializeFieldsWithThisShorthandNotation() => new ConstructorHelper1(5).field1;
  @it
  shouldInitializeFieldsWithInitializerList() => new ConstructorHelper2(6).field1;
  @it
  shouldSetFieldsToNullBeforeConstructorBodyExecutes() => new ConstructorHelper3().field1;
}

class ConstructorHelper1 {
  var field1;
  ConstructorHelper1(this.field1);
}

class ConstructorHelper2 {
  var field1;
  ConstructorHelper2(f) : field1 = f;
}

class ConstructorHelper3 {
  var field1;
  ConstructorHelper3() {
    globalFunctionParam(field1);
  }
}

@describe
class VariableDeclarations {
  @it
  shouldDefaultToNull() {
    var a, b, c;
    return a;
  }
  @it
  shouldSupportAssignmentsToExpressions() {
    var b = 2, c = 2 + 3;
    return b + c;
  }
}

@describe
class Statements {
  @it
  shouldSupportIfElseAndComparisons() {
    if (1 > 2) {
      return 0;
    } else if (2 < 1) {
      return 1;
    } else {
      if (3 + 2 >= 5) {
        return 2;
      }
      return 3;
    }
  }
  @it
  shouldSupportForLoops() {
    var j = 0;
    for (var i = 1; i < 5; i++) {
      j++;
    }
    return j;
  }
  @it
  shouldSupportForLoopsWithEmptyParts() {
    var i = 0;
    for (; globalFunctionParam(i) < 100;) {
      i = 200;
    }
    for (; false;)
      i = 0;
    return i;
  }
}

@describe
class Lists {
  @it
  shouldSupportLiterals() {
    return [1, 2, 3];
  }
  @it
  shouldIgnoreConstructorArguments() {
    return new List(10);
  }
  @it
  shouldAddElementsWithPush() {
    var a = new List();
    a.add(5);
    return a[0];
  }
}





