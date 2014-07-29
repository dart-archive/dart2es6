spyOnMe() => 1;
spyOnMeToo(a) => a;

class Test0 {
}

class Test1 {
  method1() {}
  method2() => null;
  return1() {
    return 1;
  }
  return2() => 2;
  return3() => 1 + 2;
  return4() => 2 * 2;
  return5() => 20 / 4;
  return6() => 20 / 3;
  return7() => 20 % 13;
  returnAString() => "return" + "A" "String";
}

class Test2 {
  add(a, b) {
    return a + b;
  }
  echo([something]) {
    return something;
  }
  echo2([something = 1+1]) {
    return something;
  }
}

class Test3 {
  Test3() {
    spyOnMe();
  }
}

class Test4 {
  var field1;
  var field2 = 2;
  var field3 = spyOnMe() + 2;
  Test4();
}

class Test5 {
  var field1;
  Test5(this.field1);
}

class Test6 {
  var field1;
  Test6(f) : field1 = f;
}

class Test7 {
  var field1;
  Test7() {
    spyOnMeToo(field1);
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
    for (; spyOnMeToo(i) < 100;) {
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





