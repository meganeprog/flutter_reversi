import 'game_logic_interface.dart';

/// ゲームロジックの実装
class GameLogic implements GameLogicInterface {

  /// 初期化
  @override
  void init() {
    _turn = Stone.white;
    _board = [
      [Stone.blank, Stone.blank, Stone.blank, Stone.blank, Stone.blank, Stone.blank, Stone.blank, Stone.blank],
      [Stone.blank, Stone.blank, Stone.blank, Stone.blank, Stone.blank, Stone.blank, Stone.blank, Stone.blank],
      [Stone.blank, Stone.blank, Stone.blank, Stone.blank, Stone.blank, Stone.blank, Stone.blank, Stone.blank],
      [Stone.blank, Stone.blank, Stone.blank, Stone.white, Stone.black, Stone.blank, Stone.blank, Stone.blank],
      [Stone.blank, Stone.blank, Stone.blank, Stone.black, Stone.white, Stone.blank, Stone.blank, Stone.blank],
      [Stone.blank, Stone.blank, Stone.blank, Stone.blank, Stone.blank, Stone.blank, Stone.blank, Stone.blank],
      [Stone.blank, Stone.blank, Stone.blank, Stone.blank, Stone.blank, Stone.blank, Stone.blank, Stone.blank],
      [Stone.blank, Stone.blank, Stone.blank, Stone.blank, Stone.blank, Stone.blank, Stone.blank, Stone.blank],
    ];
  }  
  late String name;

  /// ボードの行数を取得する
  @override
  int get boardRows => _board.length;

  /// ボードの列数を取得する
  @override
  int get boardColumns => _board[0].length;

  /// 現在の番を取得する
  @override
  Stone get turn => _turn;

  /// 指定された場所の石を取得する
  @override
  Stone getStone(int row, int column) {
    assert(row >= 0 && row < boardRows && column >= 0 && column < boardColumns);
    return _board[row][column];
  }

  /// 置かれている石の数を取得する
  @override
  int numberOfStone(Stone stone)
  {
    int count = 0;
    for (var rows in _board) {
      for (var item in rows) {
        if (item == stone) {
          count++;
        }
      }
    }
    return count;
  }

  /// 指定された場所に石がおける場合に、裏返せる場所のリストを返す
  /// 
  /// 置ける場合は、裏返せる場所のリストを返す
  /// 置けない場合は、空のリストを返す
  @override
  List<Position> getReversePositions(int row, int column, Stone stone) {
    assert(row >= 0 && row < boardRows && column >= 0 && column < boardColumns);
    assert(stone != Stone.blank);
    List<Position> reversePositions = List<Position>.empty(growable: true);
    reversePositions.addAll(_getReversePositions(row, column, -1,  0, stone));  // 左方向
    reversePositions.addAll(_getReversePositions(row, column,  1,  0, stone));  // 右方向
    reversePositions.addAll(_getReversePositions(row, column,  0, -1, stone));  // 上方向
    reversePositions.addAll(_getReversePositions(row, column,  0,  1, stone));  // 下方向
    reversePositions.addAll(_getReversePositions(row, column, -1, -1, stone));  // 左上方向
    reversePositions.addAll(_getReversePositions(row, column, -1,  1, stone));  // 左下方向
    reversePositions.addAll(_getReversePositions(row, column,  1, -1, stone));  // 右上方向
    reversePositions.addAll(_getReversePositions(row, column,  1,  1, stone));  // 右下方向
    return reversePositions;
  }

  /// 指定された場所に石を置く
  @override
  void putStone(int row, int column, Stone stone) {
    assert(row >= 0 && row < boardRows && column >= 0 && column < boardColumns);
    assert(stone == Stone.black || stone == Stone.white);
    _board[row][column] = stone;
  }

  /// 指定された場所の石を裏返す
  @override
  void reverseStone(int row, int column)
  {
    assert(row >= 0 && row < boardRows && column >= 0 && column < boardColumns);
    assert(_board[row][column] == Stone.black || _board[row][column] == Stone.white);
    _board[row][column] = _board[row][column] == Stone.white ? Stone.black : Stone.white;
  }

  /// 次のターンへ
  /// 
  /// 双方とも打ち手がなくなったら false を返す
  @override
  bool changeTurn() {
    clearHint();
    Stone nextTurn = _turn == Stone.white ? Stone.black : Stone.white;
    if (_canPut(nextTurn)) {
      _turn = nextTurn;
      return true;
    }
    // もう一度同じ人のターン
    return _canPut(_turn);
  }

  /// 現在のターンで配置可能な場所にヒントを設定する
  @override
  void hint() {
    for (int row = 0; row < boardRows; row++) {
      for (int column = 0; column < boardColumns; column++) {
        if (_board[row][column] == Stone.blank) {
          if (getReversePositions(row, column, _turn).isNotEmpty) {
            _board[row][column] = _turn == Stone.black ? Stone.blackHint : Stone.whiteHint;
          }
        }
      }
    }
  }

  /// ヒントをクリアする
  @override
  void clearHint() {
    for (int row = 0; row < boardRows; row++) {
      for (int column = 0; column < boardColumns; column++) {
        if (_board[row][column] == Stone.blackHint || _board[row][column] == Stone.whiteHint) {
          _board[row][column] = Stone.blank;
        }
      }
    }
  }

  List<Position> _getReversePositions(int row, int column, int rowDir, int columnDir, Stone stone) {
    Stone oppositeStone = stone == Stone.white ? Stone.black : Stone.white;
    List<Position> reversePositions = List<Position>.empty(growable: true);
    while (true) {
      row += rowDir;
      column += columnDir;
      if (row < 0 || row >= boardRows || column < 0 || column >= boardColumns) {
        // 端に到達したら置けない
        return List<Position>.empty();
      }
      if (_board[row][column] == oppositeStone) {
        // 進行方向に別の色の石があればリストに追加
        reversePositions.add(Position(row, column));
      }
      else if (_board[row][column] == stone) {
        // 1個でも別の色の石があれば置ける
        return reversePositions;
      }
      else {
        // 何も置かれていない場所に到達したら置けない
        return List<Position>.empty();
      }
    }
  }

  bool _canPut(Stone stone) {
    for (int row = 0; row < boardRows; row++) {
      for (int column = 0; column < boardColumns; column++) {
        if (_board[row][column] == Stone.blank) {
          if (getReversePositions(row, column, stone).isNotEmpty) {
            return true;
          }
        }
      }
    }
    return false;
  }
  
  late List<List<Stone>> _board;  /// ボード
  Stone _turn = Stone.white;  /// ターン
}