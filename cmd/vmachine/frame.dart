class Frame {
  Map<String, int> scope;

  Frame() : scope = Map<String, int>();

  String toString() => scope.toString();
}
