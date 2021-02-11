
# Реализация учебного языка PL/0 для закрепления основ трансляции

«‎Язык PL/0 — учебный язык программирования, использующийся в качестве примера разработки компилятора.» - [источник](http://progopedia.ru/language/pl0/)

### Сборка
```bash
# зависимости: make, dart-sdk-2.x
make
```

### Test-CLI
```bash
# дамп AST
./pl0 examples/fact.pas
```

### TODO
- [x] Lexer
- [x] Parser
- [ ] Semantic analyzer
- [ ] Smarter error handling
- [ ] Stupid optimization
- [ ] Compiler
- [ ] Virtual Machine
- [ ] CLI
- [ ] Testing and debug
