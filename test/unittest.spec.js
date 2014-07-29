import $ from "unittest";

describe("Classes", function() {
  it("should be transpiled", function() {
    expect(Test0).toBeDefined();
  });

  it("should be able to be instantiated", function() {
    expect(new Test0()).toBeDefined();
  });

  it("should define methods", function() {
    expect(new Test1().method1).toBeDefined();
  });

  it("should define expression methods", function() {
    expect(new Test1().method2).toBeDefined();
  });
});


describe("Constructor", function() {
  it("should preserve its body", function() {
    spyOn(window, "spyOnMe");
    var t = new Test3();
    expect(spyOnMe).toHaveBeenCalled();
  });

  it("should set declared fields", function() {
    var t = new Test4();
    expect(t.field1).toBe(null);
    expect(t.field2).toEqual(2);
    expect(t.field3).toEqual(3);
  });

  it("should set fields with `this.` param", function() {
    var t = new Test5(5);
    expect(t.field1).toEqual(5);
  });

  it("should set fields with initializer list", function() {
    var t = new Test6(6);
    expect(t.field1).toEqual(6);
  });

  it("should set unset fields to values before function body", function() {
    spyOn(window, "spyOnMeToo");
    var t = new Test7();
    expect(spyOnMeToo).toHaveBeenCalledWith(null);
  });
});


describe("Functions", function() {
  it("should be able to be top level", function() {
    expect(spyOnMe()).toEqual(1);
  });

  it("should return values", function() {
    var t = new Test1();
    expect(t.return1()).toEqual(1);
    expect(t.return2()).toEqual(2);
  });

  it("should accept normal arguments", function() {
    expect(new Test2().add(1, 2)).toEqual(3);
  });

  it("should accept positional arguments", function() {
    expect(new Test2().echo(4)).toEqual(4);
  });

  it("should default positional arguments to null", function() {
    expect(new Test2().echo()).toBe(null);
  });

  it("should use default arguments", function() {
    expect(new Test().echo2()).toEqual(2);
  });
});


describe("Expressions", function() {
  it("should support arithmetic", function() {
    var t = new Test1();
    expect(t.return3()).toEqual(3);
    expect(t.return4()).toEqual(4);
    expect(t.return5()).toEqual(5);
    expect(t.return6()).toEqual(20/3);
    expect(t.return7()).toEqual(7);
  });

  it("should support implicit string concatenation", function() {
    expect(new Test1().returnAString()).toEqual("returnAString");
  })
});


describe("Statements", function() {
  it("should support variable declaration", function() {
    expect(new Test8().vardecl1()).toBe(null);
    expect(new Test8().vardecl2()).toEqual(7);
  });

  it("should support if else & comparisons", function() {
    expect(new Test8().ifelse()).toEqual(2);
  });

  it("should support for loops", function() {
    expect(new Test8().forloop1()).toEqual(5);
    expect(new Test8().forloop2()).toEqual(200);
  });
});


describe("Builtins", function() {
  it("should support Lists", function() {
    var t = new Test8();
    expect(t.list1()).toEqual([1,2,3]);
    expect(t.list2()).toEqual([]);
    expect(t.list3()).toEqual(5);
  })
});





