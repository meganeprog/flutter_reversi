
/// 石の状態
enum Stone {
  blank,      /// 何も置かれていない
  white,      /// 白
  black,      /// 黒
  whiteHint,  /// 白石を置く候補
  blackHint,  /// 黒石を置く候補
}

/// 石のポジションをあらわすクラス
class Position {
  int row = 0;
  int column =0;
  Position(this.row, this.column);
}

/// ゲームロジックのインターフェース
abstract class GameLogicInterface {
  /// 初期化
  void init();

  /// ボードの行数を取得する
  int get boardRows;

  /// ボードの列数を取得する
  int get boardColumns;

  /// 現在の番を取得する
  Stone get turn;

  /// 指定された場所の石を取得する
  Stone getStone(int row, int column);

  /// 置かれている石の数を取得する
  int numberOfStone(Stone stone);

  /// 指定された場所に石がおける場合に、裏返せる場所のリストを返す
  /// 
  /// 置ける場合は、裏返せる場所のリストを返す
  /// 置けない場合は、空のリストを返す
  List<Position> getReversePositions(int row, int column, Stone stone);

  /// 指定された場所に石を置く
  void putStone(int row, int column, Stone stone);

  /// 指定された場所の石を裏返す
  void reverseStone(int row, int column);

  /// 次のターンへ
  /// 
  /// 双方とも打ち手がなくなったら false を返す
  bool changeTurn();

  /// 現在のターンで配置可能な場所にヒントを設定する
  void hint();

  /// ヒントをクリアする
  void clearHint();
}
