import "package:guinness/guinness.dart";
import 'package:analyzer/analyzer.dart';
import "package:dart2es6/dart2es6.dart";

main() {
  test(INPUT_WATCHGROUP, "");
}

test(String input, [String output]) {
//  print(input);
  print('---debug---');
  var cu = parseCompilationUnit(input);
  var result = new Transpiler.fromAst(cu).transpile();
  print("---output---");
  print(result);
}

var INPUT_SANDBOX = r"""
class Test {
  start() {
    if (1 == 1) {
      stop1();
    } else if (2 == 2) {
      stop2();
    } else {
      stop3();
    }
  }
}
""".trim();

var INPUT_WATCHGROUP = r"""
class WatchGroup implements _EvalWatchList, _WatchGroupList {
  /** A unique ID for the WatchGroup */
  final String id;
  /**
   * A marker to be inserted when a group has no watches. We need the marker to
   * hold our position information in the linked list of all [Watch]es.
   */
  final _EvalWatchRecord _marker = new _EvalWatchRecord.marker();

  /** All Expressions are evaluated against a context object. */
  final Object context;

  /** [ChangeDetector] used for field watching */
  final ChangeDetectorGroup<_Handler> _changeDetector;
  /** A cache for sharing sub expression watching. Watching `a` and `a.b` will
  * watch `a` only once. */
  final Map<String, WatchRecord<_Handler>> _cache;
  final RootWatchGroup _rootGroup;

  /// STATS: Number of field watchers which are in use.
  int _fieldCost = 0;
  int _collectionCost = 0;
  int _evalCost = 0;

  /// STATS: Number of field watchers which are in use including child [WatchGroup]s.
  int get fieldCost => _fieldCost;
  int get totalFieldCost {
    var cost = _fieldCost;
    WatchGroup group = _watchGroupHead;
    while (group != null) {
      cost += group.totalFieldCost;
      group = group._nextWatchGroup;
    }
    return cost;
  }

  /// STATS: Number of collection watchers which are in use including child [WatchGroup]s.
  int get collectionCost => _collectionCost;
  int get totalCollectionCost {
    var cost = _collectionCost;
    WatchGroup group = _watchGroupHead;
    while (group != null) {
      cost += group.totalCollectionCost;
      group = group._nextWatchGroup;
    }
    return cost;
  }

  /// STATS: Number of invocation watchers (closures/methods) which are in use.
  int get evalCost => _evalCost;

  /// STATS: Number of invocation watchers which are in use including child [WatchGroup]s.
  int get totalEvalCost {
    var cost = _evalCost;
    WatchGroup group = _watchGroupHead;
    while (group != null) {
      cost += group.evalCost;
      group = group._nextWatchGroup;
    }
    return cost;
  }

  int _nextChildId = 0;
  _EvalWatchRecord _evalWatchHead, _evalWatchTail;
  /// Pointer for creating tree of [WatchGroup]s.
  WatchGroup _parentWatchGroup;
  WatchGroup _watchGroupHead, _watchGroupTail;
  WatchGroup _prevWatchGroup, _nextWatchGroup;

  WatchGroup._child(_parentWatchGroup, this._changeDetector, this.context,
                    this._cache, this._rootGroup)
      : _parentWatchGroup = _parentWatchGroup,
        id = '${_parentWatchGroup.id}.${_parentWatchGroup._nextChildId++}'
  {
    _marker.watchGrp = this;
    _evalWatchTail = _evalWatchHead = _marker;
  }

  WatchGroup._root(this._changeDetector, this.context)
      : id = '',
        _rootGroup = null,
        _parentWatchGroup = null,
        _cache = new HashMap<String, WatchRecord<_Handler>>()
  {
    _marker.watchGrp = this;
    _evalWatchTail = _evalWatchHead = _marker;
  }

  get isAttached {
    var group = this;
    var root = _rootGroup;
    while (group != null) {
      if (group == root){
        return true;
      }
      group = group._parentWatchGroup;
    }
    return false;
  }

  Watch watch(AST expression, ReactionFn reactionFn) {
    WatchRecord<_Handler> watchRecord = _cache[expression.expression];
    if (watchRecord == null) {
      _cache[expression.expression] = watchRecord = expression.setupWatch(this);
    }
    return watchRecord.handler.addReactionFn(reactionFn);
  }

  /**
   * Watch a [name] field on [lhs] represented by [expression].
   *
   * - [name] the field to watch.
   * - [lhs] left-hand-side of the field.
   */
  WatchRecord<_Handler> addFieldWatch(AST lhs, String name, String expression) {
    var fieldHandler = new _FieldHandler(this, expression);

    // Create a Record for the current field and assign the change record
    // to the handler.
    var watchRecord = _changeDetector.watch(null, name, fieldHandler);
    _fieldCost++;
    fieldHandler.watchRecord = watchRecord;

    WatchRecord<_Handler> lhsWR = _cache[lhs.expression];
    if (lhsWR == null) {
      lhsWR = _cache[lhs.expression] = lhs.setupWatch(this);
    }

    // We set a field forwarding handler on LHS. This will allow the change
    // objects to propagate to the current WatchRecord.
    lhsWR.handler.addForwardHandler(fieldHandler);

    // propagate the value from the LHS to here
    fieldHandler.acceptValue(lhsWR.currentValue);
    return watchRecord;
  }

  WatchRecord<_Handler> addCollectionWatch(AST ast) {
    var collectionHandler = new _CollectionHandler(this, ast.expression);
    var watchRecord = _changeDetector.watch(null, null, collectionHandler);
    _collectionCost++;
    collectionHandler.watchRecord = watchRecord;
    WatchRecord<_Handler> astWR = _cache[ast.expression];
    if (astWR == null) {
      astWR = _cache[ast.expression] = ast.setupWatch(this);
    }

    // We set a field forwarding handler on LHS. This will allow the change
    // objects to propagate to the current WatchRecord.
    astWR.handler.addForwardHandler(collectionHandler);

    // propagate the value from the LHS to here
    collectionHandler.acceptValue(astWR.currentValue);
    return watchRecord;
  }

  /**
   * Watch a [fn] function represented by an [expression].
   *
   * - [fn] function to evaluate.
   * - [argsAST] list of [AST]es which represent arguments passed to function.
   * - [expression] normalized expression used for caching.
   * - [isPure] A pure function is one which holds no internal state. This implies that the
   *   function is idempotent.
   */
  _EvalWatchRecord addFunctionWatch(Function fn, List<AST> argsAST,
                                    Map<Symbol, AST> namedArgsAST,
                                    String expression, bool isPure) =>
      _addEvalWatch(null, fn, null, argsAST, namedArgsAST, expression, isPure);

  /**
   * Watch a method [name]ed represented by an [expression].
   *
   * - [lhs] left-hand-side of the method.
   * - [name] name of the method.
   * - [argsAST] list of [AST]es which represent arguments passed to method.
   * - [expression] normalized expression used for caching.
   */
  _EvalWatchRecord addMethodWatch(AST lhs, String name, List<AST> argsAST,
                                  Map<Symbol, AST> namedArgsAST,
                                  String expression) =>
     _addEvalWatch(lhs, null, name, argsAST, namedArgsAST, expression, false);



  _EvalWatchRecord _addEvalWatch(AST lhsAST, Function fn, String name,
                                 List<AST> argsAST,
                                 Map<Symbol, AST> namedArgsAST,
                                 String expression, bool isPure) {
    _InvokeHandler invokeHandler = new _InvokeHandler(this, expression);
    var evalWatchRecord = new _EvalWatchRecord(
        _rootGroup._fieldGetterFactory, this, invokeHandler, fn, name,
        argsAST.length, isPure);
    invokeHandler.watchRecord = evalWatchRecord;

    if (lhsAST != null) {
      var lhsWR = _cache[lhsAST.expression];
      if (lhsWR == null) {
        lhsWR = _cache[lhsAST.expression] = lhsAST.setupWatch(this);
      }
      lhsWR.handler.addForwardHandler(invokeHandler);
      invokeHandler.acceptValue(lhsWR.currentValue);
    }

    // Convert the args from AST to WatchRecords
    for (var i = 0; i < argsAST.length; i++) {
      var ast = argsAST[i];
      WatchRecord<_Handler> record = _cache[ast.expression];
      if (record == null) {
        record = _cache[ast.expression] = ast.setupWatch(this);
      }
      _ArgHandler handler = new _PositionalArgHandler(this, evalWatchRecord, i);
      _ArgHandlerList._add(invokeHandler, handler);
      record.handler.addForwardHandler(handler);
      handler.acceptValue(record.currentValue);
    }

    namedArgsAST.forEach((Symbol name, AST ast) {
      WatchRecord<_Handler> record = _cache[ast.expression];
      if (record == null) {
        record = _cache[ast.expression] = ast.setupWatch(this);
      }
      _ArgHandler handler = new _NamedArgHandler(this, evalWatchRecord, name);
      _ArgHandlerList._add(invokeHandler, handler);
      record.handler.addForwardHandler(handler);
      handler.acceptValue(record.currentValue);
    });

    // Must be done last
    _EvalWatchList._add(this, evalWatchRecord);
    _evalCost++;
    if (_rootGroup.isInsideInvokeDirty) {
      // This check means that we are inside invoke reaction function.
      // Registering a new EvalWatch at this point will not run the
      // .check() on it which means it will not be processed, but its
      // reaction function will be run with null. So we process it manually.
      evalWatchRecord.check();
    }
    return evalWatchRecord;
  }

  WatchGroup get _childWatchGroupTail {
    var tail = this, nextTail;
    while ((nextTail = tail._watchGroupTail) != null) {
      tail = nextTail;
    }
    return tail;
  }

  /**
   * Create a new child [WatchGroup].
   *
   * - [context] if present the the child [WatchGroup] expressions will evaluate
   * against the new [context]. If not present than child expressions will
   * evaluate on same context allowing the reuse of the expression cache.
   */
  WatchGroup newGroup([Object context]) {
    _EvalWatchRecord prev = _childWatchGroupTail._evalWatchTail;
    _EvalWatchRecord next = prev._nextEvalWatch;
    var childGroup = new WatchGroup._child(
        this,
        _changeDetector.newGroup(),
        context == null ? this.context : context,
        new HashMap<String, WatchRecord<_Handler>>(),
        _rootGroup == null ? this : _rootGroup);
    _WatchGroupList._add(this, childGroup);
    var marker = childGroup._marker;

    marker._prevEvalWatch = prev;
    marker._nextEvalWatch = next;
    prev._nextEvalWatch = marker;
    if (next != null) next._prevEvalWatch = marker;

    return childGroup;
  }

  /**
   * Remove/destroy [WatchGroup] and all of its [Watches].
   */
  void remove() {
    // TODO:(misko) This code is not right.
    // 1) It fails to release [ChangeDetector] [WatchRecord]s.

    _WatchGroupList._remove(_parentWatchGroup, this);
    _nextWatchGroup = _prevWatchGroup = null;
    _changeDetector.remove();
    _rootGroup._removeCount++;
    _parentWatchGroup = null;

    // Unlink the _watchRecord
    _EvalWatchRecord firstEvalWatch = _evalWatchHead;
    _EvalWatchRecord lastEvalWatch = _childWatchGroupTail._evalWatchTail;
    _EvalWatchRecord previous = firstEvalWatch._prevEvalWatch;
    _EvalWatchRecord next = lastEvalWatch._nextEvalWatch;
    if (previous != null) previous._nextEvalWatch = next;
    if (next != null) next._prevEvalWatch = previous;
    _evalWatchHead._prevEvalWatch = null;
    _evalWatchTail._nextEvalWatch = null;
    _evalWatchHead = _evalWatchTail = null;
  }

  toString() {
    var lines = [];
    if (this == _rootGroup) {
      var allWatches = [];
      var watch = _evalWatchHead;
      var prev = null;
      while (watch != null) {
        allWatches.add(watch.toString());
        assert(watch._prevEvalWatch == prev);
        prev = watch;
        watch = watch._nextEvalWatch;
      }
      lines.add('WATCHES: ${allWatches.join(', ')}');
    }

    var watches = [];
    var watch = _evalWatchHead;
    while (watch != _evalWatchTail) {
      watches.add(watch.toString());
      watch = watch._nextEvalWatch;
    }
    watches.add(watch.toString());

    lines.add('WatchGroup[$id](watches: ${watches.join(', ')})');
    var childGroup = _watchGroupHead;
    while (childGroup != null) {
      lines.add('  ' + childGroup.toString().replaceAll('\n', '\n  '));
      childGroup = childGroup._nextWatchGroup;
    }
    return lines.join('\n');
  }
}
""";

var INPUT_STOPWATCH = """
class AvgStopwatch {
  int _count = 0;
  String name;

  static num numCreated = 0;

  AvgStopwatch(this.name) {
    print('new stopwatch created!');
  }

  int get count => _count;
  set count(val) => _count = val;

  void reset() {
    _count = 0;
    super.reset();
  }

  int increment(int count) => _count += count;

  double get ratePerMs => elapsedMicroseconds == 0
      ? 0.0
      : _count / elapsedMicroseconds * 1000;
}
""".trim();

var INPUT_BASIC = """
library foo;

class HelloWorld {
  final String greeting;
  String name = 'World';

  HelloWorld(this.greeting);

  greet() {
    return greeting + name;
  }

}
""".trim();
