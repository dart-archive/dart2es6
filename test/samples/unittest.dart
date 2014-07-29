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
class Constructor1 {
  var field1;
  var field2 = 2;
  var field3 = globalFunction() + 2;
  Constructor1();
  @it
  shouldSetDeclaredFieldsToNullByDefault() => field1;
  @it
  shouldSetFieldsWithDefaultValue() => field2;
  @it
  shouldCalculateFieldDefaultValues() => field3;
}

@describe
class Constructor2 {

}

@helperFor(Constructor2)
class ConstructorHelper1 {
  var field1;
  ConstructorHelper1(this.field1);
}

@helperFor(Constructor2)
class ConstructorHelper2 {
  var field1;
  ConstructorHelper2(f) : field1 = f;
}

@helperFor(Constructor2)
class ConstructorHelper3 {
  var field1;
  ConstructorHelper3() {
    globalFunctionParam(field1);
  }
}

class Test8 {
  vardecl1() {
    var a, b, c;
    return a;
  }

  vardecl2() {
    var b = 2, c = 2 + 3;
    return b + c;
  }

  ifelse() {
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

  forloop1() {
    var j = 0;
    for (var i = 1; i < 5; i++) {
      j++;
    }
    return j;
  }

  forloop2() {
    var i = 0;
    for (; globalFunctionParam(i) < 100;) {
      i = 200;
    }
    for (; false;) i = 0;
    return i;
  }

  list1() {
    return [1, 2, 3];
  }

  list2() {
    return new List(10);
  }

  list3() {
    var a = new List();
    a.add(5);
    return a[0];
  }
}





