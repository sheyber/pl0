import 'frame.dart';
import 'pcode.dart';

class VirtualMachine {
  List<Frame> _frames;
  Map<String, int> _labelTable;
  List<int> _stack;
  List<int> _retStack;

  VirtualMachine()
      : _frames = List<Frame>(),
        _labelTable = Map<String, int>(),
        _stack = List<int>(),
        _retStack = List<int>();

  void _pushToStack(int value) => _stack.add(value);
  int _popFromStack() => _stack.removeLast();

  void _pushFrame() => _frames.add(Frame());
  void _popFrame() => _frames.removeLast();
  void _setVariable(String name) {
    for (var i = 0; i < _frames.length; i++)
      if (_frames[i].scope.containsKey(name)) {
        _frames[i].scope[name] = _popFromStack();
        return;
      }
    _frames.last.scope[name] = _popFromStack();
  }

  int _getVariable(String name) {
    for (var element in _frames)
      if (element.scope.containsKey(name)) return element.scope[name];
    return null;
  }

  void _searchLabels(List<PCode> pcodes) {
    for (var i = 0; i < pcodes.length; i++)
      if (pcodes[i].type == Instructions.LABEL) _labelTable[pcodes[i].arg] = i;
    assert(_labelTable.containsKey('main_start_point') == true);
  }

  void _execute(List<PCode> pcodes) {
    loop:
    for (var i = 0; i < pcodes.length; i++) {
      var current = pcodes[i];

      switch (current.type) {
        case Instructions.PUSH:
          _pushToStack(int.parse(current.arg));
          break;
        case Instructions.POP:
          _popFromStack();
          break;
        case Instructions.ADD:
          int a = _popFromStack();
          int b = _popFromStack();
          if (a != null && b != null) _pushToStack(a + b);
          break;
        case Instructions.SUB:
          var t = _popFromStack();
          _pushToStack(_popFromStack() - t);
          break;
        case Instructions.MUL:
          _pushToStack(_popFromStack() * _popFromStack());
          break;
        case Instructions.DIV:
          var t = _popFromStack();
          _pushToStack((_popFromStack() / t) as int);
          break;
        case Instructions.EQ:
          _pushToStack((_popFromStack() == _popFromStack()) ? 1 : 0);
          break;
        case Instructions.NOT_EQ:
          _pushToStack((_popFromStack() != _popFromStack()) ? 1 : 0);
          break;
        case Instructions.MORE:
          var t = _popFromStack();
          _pushToStack((_popFromStack() > t) ? 1 : 0);
          break;
        case Instructions.LESS:
          var t = _popFromStack();
          _pushToStack((_popFromStack() < t) ? 1 : 0);
          break;
        case Instructions.STORE:
          _setVariable(current.arg);
          break;
        case Instructions.FETCH:
          _pushToStack(_getVariable(current.arg));
          break;
        case Instructions.CALL:
          if (current.arg == 'print') {
            print(_getVariable('out'));
            break;
          }
          _pushFrame();
          _retStack.add(i);
          i = _labelTable[current.arg];
          break;
        case Instructions.JZ:
          if (_popFromStack() == 0) i = _labelTable[current.arg];
          break;
        case Instructions.JNZ:
          if (_popFromStack() != 0) i = _labelTable[current.arg];
          break;
        case Instructions.JMP:
          i = _labelTable[current.arg];
          break;
        case Instructions.RET:
          _popFrame();
          i = _retStack.removeLast();
          break;
        case Instructions.HALT:
          break loop;
      }
    }
  }

  void run(List<PCode> pcodes, {dumpStack = false, dumpFrames = false}) {
    _frames.add(Frame()); // global scope
    _pushToStack(0);
    _searchLabels(pcodes);
    try {
      _execute(pcodes);
    } catch (e) {
      print(e);
    }
    if (dumpStack) print(_stack);
    if (dumpFrames) print(_frames.map((e) => e.toString()));
  }
}
