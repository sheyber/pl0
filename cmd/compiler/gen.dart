import '../vmachine/pcode.dart';
import 'syntax_analyzer/parser.dart';

class CodeGenerator {
  List<Map> _program;
  List<PCode> _pcodes;
  int _temp;
  Map<String, String> _tableOfConstants;

  CodeGenerator(this._program)
      : _pcodes = List<PCode>(),
        _temp = 0,
        _tableOfConstants = Map<String, String>();

  void _addPCode(Instructions instruction, [String arg = null]) {
    var pcode = PCode(instruction, arg);
    _pcodes.add(pcode);
  }

  void _gen(Map node) {
    if (node == null) return;
    var type = node['type'];
    switch (type) {
      case NodeType.CONST_NUMBER:
        _addPCode(Instructions.PUSH, node['value']);
        break;
      case NodeType.ADD:
        _gen(node['left']);
        _gen(node['right']);
        _addPCode(Instructions.ADD);
        break;
      case NodeType.SUB:
        _gen(node['left']);
        _gen(node['right']);
        _addPCode(Instructions.SUB);
        break;
      case NodeType.MULTIPLY:
        _gen(node['left']);
        _gen(node['right']);
        _addPCode(Instructions.MUL);
        break;
      case NodeType.DIV:
        _gen(node['left']);
        _gen(node['right']);
        _addPCode(Instructions.DIV);
        break;
      case NodeType.LESS:
        _gen(node['left']);
        _gen(node['right']);
        _addPCode(Instructions.LESS);
        break;
      case NodeType.MORE:
        _gen(node['left']);
        _gen(node['right']);
        _addPCode(Instructions.MORE);
        break;
      case NodeType.EQ:
        _gen(node['left']);
        _gen(node['right']);
        _addPCode(Instructions.EQ);
        break;
      case NodeType.NOT_EQ:
        _gen(node['left']);
        _gen(node['right']);
        _addPCode(Instructions.NOT_EQ);
        break;
      case NodeType.VARIABLE_NAME:
        if (_tableOfConstants.containsKey(node['name']))
          _addPCode(Instructions.PUSH, _tableOfConstants[node['name']]);
        else
          _addPCode(Instructions.FETCH, node['name']);
        break;
      case NodeType.SET_VAR:
        _gen(node['value']);
        _addPCode(Instructions.STORE, node['name']);
        break;
      case NodeType.CALL_PROC:
        _addPCode(Instructions.CALL, node['name']);
        break;
      case NodeType.IF:
        int t = _temp++;
        _gen(node['cond']);
        _addPCode(Instructions.JZ, 'else$t');
        // _addPCode(Instructions.JMP, 'then$t');
        // _addPCode(Instructions.LABEL, 'then$t');
        _gen(node['body']);
        _addPCode(Instructions.JMP, 'else$t');
        _addPCode(Instructions.LABEL, 'else$t');
        break;
      case NodeType.WHILE:
        int t = _temp++;
        _addPCode(Instructions.LABEL, 'loop$t');
        _gen(node['cond']);
        _addPCode(Instructions.JZ, 'else_loop$t');
        _gen(node['body']);
        _addPCode(Instructions.JMP, 'loop$t');
        _addPCode(Instructions.LABEL, 'else_loop$t');
        break;
      case NodeType.MAIN_BLOCK:
        _addPCode(Instructions.LABEL, 'main_start_point');
        for (var i in node['body']) _gen(i);
        _addPCode(Instructions.HALT);
        break;
      case NodeType.BLOCK:
        for (var i in node['body']) _gen(i);
        break;
      case NodeType.SET_CONST:
        for (List i in node['pairs']) _tableOfConstants[i[0]] = i[1];
        break;
      case NodeType.PROC_DEFINE:
        _addPCode(Instructions.LABEL, node['name']);
        _gen(node['block']);
        _gen(node['body']);
        _addPCode(Instructions.RET);
        break;
    }
  }

  List<PCode> compile() {
    _addPCode(Instructions.CALL, 'main_start_point');
    _program.forEach(_gen);
    return _pcodes;
  }
}
