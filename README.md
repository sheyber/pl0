
# Реализация учебного языка PL/0 для закрепления теории по основам трансляции

«‎Язык PL/0 — учебный язык программирования, использующийся в качестве примера разработки компилятора.» - [источник](http://progopedia.ru/language/pl0/)

### Сборка
```bash
# зависимости: make, dart-sdk-2.x
make
```

### TODO
- [x] Lexer
- [x] Parser
- [x] Semantic analyzer
- [x] ~~Smarter error handling~~ ugly error handling
- [x] Stupid optimization
- [x] Code generation
- [x] Virtual Machine
- [ ] CLI
- [ ] Write tests and debug
- [ ] Refactoring

### Короткая справка об реализации & Compile design
Данная реализация является интерпретатором с этапом компиляцией
в более низкоуровневый/простой IR, что исполняется на абстрактной машине(виртуальной машине). Общая схема выглядит так:
1. Лексический анализ
2. Синтаксический анализ
3. Семантический анализ
4. Этап оптимизации
5. Кодогенерация
6. Исполнение на абстрактной машине

Вполне всё тривиально. За подробностями обращайтесь к исходникам, а далее опишу *что* есть на этапе оптимизации. В static time происходит такие оптимизации как:
- Свёртка констант
- Удаление мёртвого кода (То есть если на этапе компиляции условие в конструкциях `if` , `while` будет отрицательными, то они просто не будут сгенерированы в IR для абстрактной машины)
- Удаление общих подвыражений

Чтобы исследовать это посмотрите результат кодогенерации при двух флагов `-asm` и `-asm-no`.

### Литература
- «‎Построение компиляторов» Никлаус Вирт.
- «‎Алгоритмы и структуры данных» Никлаус Вирт.
