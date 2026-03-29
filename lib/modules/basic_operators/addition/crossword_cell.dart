enum CellType { empty, number, operator, equals, answer, blank }

class CrosswordCell {
  final int row;
  final int col;
  CellType type;
  String? value;
  int? answer;
  bool isCorrect;

  CrosswordCell({
    required this.row,
    required this.col,
    this.type = CellType.empty,
    this.value,
    this.answer,
    this.isCorrect = false,
  });

  factory CrosswordCell.fromJson(Map<String, dynamic> json) {
    return CrosswordCell(
      row: json['row'] is int
          ? json['row']
          : int.tryParse(json['row']?.toString() ?? '0') ?? 0,
      col: json['col'] is int
          ? json['col']
          : int.tryParse(json['col']?.toString() ?? '0') ?? 0,
      type: CellType.values.firstWhere(
            (t) => t.name == (json['type'] ?? 'empty'),
        orElse: () => CellType.empty,
      ),
      value: json['value']?.toString(),
      answer: json['answer'] is int
          ? json['answer']
          : int.tryParse(json['answer']?.toString() ?? ''),
      isCorrect: json['isCorrect'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'row': row,
    'col': col,
    'type': type.name,
    'value': value,
    'answer': answer,
    'isCorrect': isCorrect,
  };
}

class BankNumber {
  final int id;
  final int value;
  bool used;

  BankNumber({required this.id, required this.value, this.used = false});

  factory BankNumber.fromJson(Map<String, dynamic> json) {
    return BankNumber(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      value: json['value'] is int
          ? json['value']
          : int.tryParse(json['value']?.toString() ?? '0') ?? 0,
      used: json['used'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'value': value,
    'used': used,
  };
}
