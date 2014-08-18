# dart2es6

_The Dart to ECMAScript 6 transpiler_


## <intro>

## Design

Overview: The Dart code is tokenized, parsed, and resolved into an Abstract Syntax Tree. A visitor is used to visit each node in the tree, recursively visiting children with the same or a new visitor, depending on the need to store state across nodes. Each visitor returns a string(buffer) built from the values of its children to construct the final ES6 output.

#### AST building

AST is built by Dart's analyzer package. Analyzer (from java2dart) is still unstable and rapidly changing, so dart2es6 will require work to update as analyzer moves to 1.0. 

<HelloWorld example class>

#### Traversing the AST

- Visitor based design. Each node in the AST has an `accept` method that takes in a visitor and calls the appropriate method on it based on its type. Allows visitors to do `statements.forEach((s) => s.accept(this))` and the statements will call the appropriate method from the visitor to handle itself.
- `NullVisitor` is the base visitor that is extended by all others. It implements every possible visit method to complain and print out debugging information.
- The root of the AST is a `CompilationUnit`. A `MainVisitor` visits it, handles import/export statements, and instantiates a `ClassVisitor` for each class declaration. It also opens and pastes in files (recursively transpiled) with `part of` statements, as listed by `part` clauses. 
- The `ClassVisitor` tracks state specific to a class. It scans for fields, and stores them so child visitors can refer back to it. It also initializes static fields.
- The `BlockVisitor` is where the majority of the nodes are visited, including most of the expressions and statements.
- `ConstructorVisitor` subclasses `BlockVisitor` and initializes fields, `this.field` arguments, and sets other fields to null. Does not yet support initializer lists, multiple constructors, and inheritance. 


#### Indentation

The `IndentedStringBuffer` class in `writer.dart` implements `StringBuffer`, but provides an `indent` method that indents its contents. Visitors use this buffer to pass around parts of the finished output, and indents are added where appropriate.

## Dart features that this currently handles

- Straightforward differences
  - adjacent strings
  - `==` vs `===`
  - abstract functions
  - forEach statements
  - function declarations
  - getter setters
  - etc.
- set positional default arguments to null. (named not supported)
- implicit `this.` on fields (does not support shadowing)
- builtin constructors: List, Map, HashMap (arguments and named constructors not supported)
- builtin methods: replace `[].add` with `[].push`
- part & part of
- `A is Type` statements
- stack traces in catch clauses (`on ErrorType catch(e)` not supported)
- rethrow
- global builtins, such as `print`


## Testing Part 1 - Unit tests

Unit tests will consist of Dart classes with test methods. The classes will be transpiled to ES6, then transpiled by traceur to JavaScript. Test runner will append a main function to the Dart and JS versions that calls one method at a time. The return value and any intermediate values sent to STDOUT from calling the methods in Dart will be compared to the respective output in JS, and reported via guinness. 

Tests are in the following format:
```
@[describe | ddescribe | xdescribe]
class StringToPassToDescribe {
    @[it | iit | xit]
    stringToPassToIt() {
        … test code …
        helper(a, b, c);
        return valueToCompareWithJs;
    }

    helper(a, b, c) {
        … test code …
    }
}
```

The test runner uses regex to preprocess the test file, removing tests that should not be run according to annotations. It should then tree shake helper classes that aren't used, though this is not currently working. 

## Testing Part 2 - Change detection

As an integration test, the transpiler will transpile Angular's change detection library and its tests, then run those tests in JS. 

The library is modified to remove any unsupported features, but the following needs to be done:
- List constructor with arguments, and List.generate call.
- Overriding index `[]` operator in `prototype_map.dart`
- Named constructors
- `FunctionApply` has a `call()` method
- Named constructors

## High priority TODO's
- More unit tests & test runner upgrades/fixes
- Get change detection tests working
- Support inheritance better: inherit fields, call super constructor, etc
- Make replacement dictionaries more complete. (`[].add/push, print/console.log`, etc)

## Low priority TODO's
These things may not be worthwhile to implement, and may be better off left unsupported

- Named parameters
- Declaring variables that shadow fields or global variables
- Throw error object instead of String
- Cascades (`..` notation)
- Initializer lists
- Using types, const, & final
- Multiline strings
- Hide: `import X hide Y`
- Multiple constructors
- Assert statements
- Non-documentation comments
- Better support for `A is Type` statements
