library foo;

class HelloWorld {
  final String greeting;
  String name = 'World';

  HelloWorld(this.greeting);

  greet() {
    return greeting + name;
  }

}
