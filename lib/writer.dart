library dart2es6.writer;

/**
 * StringBuffer with indent method. Implemented inefficiently for now as a hack
 * Should be replaced later by efficient implementation that keeps track of individual lines
 * instead of redoing the entire string when indenting.
 */
class IndentedStringBuffer {

  static const String INDENT = "  ";
  StringBuffer buffer;

  factory IndentedStringBuffer([obj = ""]) {
    if (obj is IndentedStringBuffer) return obj;
    return new IndentedStringBuffer._(obj);
  }
  
  IndentedStringBuffer._(obj): buffer = new StringBuffer(obj);

  get isEmpty => buffer.isEmpty;
  get isNotEmpty => buffer.isNotEmpty;
  write(obj) => buffer.write(obj);
  writeln(obj) => buffer.writeln(obj);
  writeAll(objs) => buffer.writeAll(objs);
  clear() => buffer.clear();
  toString() => buffer.toString();

  /**
   * returns this to allow wrapping Strings with an IndentedStringBuffer to indent them, i.e.
   * "hello" => new IndentedStringBuffer("hello").indent()
   */
  IndentedStringBuffer indent([int levels = 1]) {
    var str = buffer.toString();
    buffer.clear();
    str.split('\n').forEach((line) {
      buffer.write(INDENT * levels);
      buffer.writeln(line);
    });
    return this;
  }
}
