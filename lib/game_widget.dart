import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flip_card/flip_card_controller.dart';
import 'package:flip_card/flip_card.dart';
import 'package:confetti/confetti.dart';

import 'game_logic_interface.dart';

/// ゲームのUI
class GameWidget extends StatefulWidget {
  const GameWidget(this._gameLogic, {super.key});

  @override
  State<GameWidget> createState() => _GameWidgetState(_gameLogic);

  final GameLogicInterface _gameLogic;
}

/// ゲームUIのステート
class _GameWidgetState extends State<GameWidget> with TickerProviderStateMixin {

  _GameWidgetState(this._gameLogic);

  @override
  initState() {
    super.initState();

    _gameLogic.init();

    // 石を裏返すためのコントローラーを生成
    _stoneFlipControllers = List.generate(
      _gameLogic.boardRows, 
      (int index) => List.generate(
        _gameLogic.boardColumns, 
        (int index) => FlipCardController()
      )
    );

    // ターンをあらわすカードのアニメーション
    _turnCardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _turnCardAnimation = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween(begin: 0.0, end: 0.5).chain(CurveTween(curve: Curves.ease)),
        weight: 15,
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(0.5),
        weight: 70,
      ),
      TweenSequenceItem<double>(
        tween: Tween(begin: 0.5, end: 1.0).chain(CurveTween(curve: Curves.ease)),
        weight: 15,
      ),
    ]).animate(_turnCardAnimationController)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animationPlaying = false;
          _gameLogic.hint();
        }
      });

    // 終了アニメーション
    _finishCardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _finishCardAnimation = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween(begin: 0.0, end: 0.5).chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
      TweenSequenceItem<double>(
        tween: Tween(begin: 0.5, end: 0.4).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem<double>(
        tween: Tween(begin: 0.4, end: 0.5).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_finishCardAnimationController)
      ..addListener(() {
        setState(() {});
      });

    // 紙吹雪のコントローラーの初期化
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 500),
    );

    // 最初のターンの通知
    _animationPlaying = true;
    Future.delayed(const Duration(seconds: 1), () {
      _turnCardAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _turnCardAnimationController.dispose();
    _finishCardAnimationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reversi'),
      ),
      body: Stack(
        children: <Widget>[
          Center(
            child: _buildBoard(context),
          ),
          _buildTurnCard(context),
          _buildFinishCard(context),
          _buildConfetti(context),
        ],
      ),
    );
  }

  Future<void> _putStone(int row, int column) async {
    if (_animationPlaying) {
      return;
    }
    List<Position> reversePositions = _gameLogic.getReversePositions(row, column, _gameLogic.turn);
    if (reversePositions.isNotEmpty) {
      _animationPlaying = true;
      setState(() {
        _gameLogic.clearHint();
        _gameLogic.putStone(row, column, _gameLogic.turn);
      });
      await Future.delayed(const Duration(milliseconds: 200));
      for (Position position in reversePositions) {
        _stoneFlipControllers[position.row][position.column].toggleCard();
        await Future.delayed(const Duration(milliseconds: 250));
        setState(() {
          _gameLogic.reverseStone(position.row, position.column);
          _stoneFlipControllers[position.row][position.column].toggleCardWithoutAnimation();
        });
      }
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() {
        if (_gameLogic.changeTurn()) {
          _turnCardAnimationController.reset();
          _turnCardAnimationController.forward();
        } else {
          // ゲームオーバー
          _finishCardAnimationController.forward();
          if (_gameLogic.numberOfStone(Stone.white) != _gameLogic.numberOfStone(Stone.black)) {
            _confettiController.play();
          }
        }
      });
    }
  }

  Widget _buildBoard(BuildContext context) {
    final double boardSize = _getBoardSize(context);

    int rows = _gameLogic.boardRows;
    int columns = _gameLogic.boardColumns;

    return Container(
      margin: const EdgeInsets.all(5.0),
      color: Colors.black,
      width: boardSize,
      height: boardSize,
      child: Column(children: <Widget>[
        for (int row = 0; row < rows; row++) ... {
          Expanded(
            child: Row(
              children: <Widget> [
                for (int column = 0; column < columns; column++) ... {
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(1.0),
                      color:Colors.green,
                      child: _buildStone(context, row, column),
                    ),
                  )
                }
              ]
            )
          )  
        }
      ])
    );
  }

  Widget _buildStone(BuildContext context, int row, int column) {
    final double boardSize = _getBoardSize(context);
    final double squareSize = boardSize / _gameLogic.boardRows;
    final Stone stone = _gameLogic.getStone(row, column);

    if (stone == Stone.blank) {
      return Container();
    }
    else if (stone == Stone.blackHint || stone == Stone.whiteHint) {
      final Color stoneColor = stone == Stone.blackHint ? Colors.black : Colors.white;
      return SizedBox(
        width: squareSize,
        height: squareSize,
        child: ElevatedButton (
          style: ElevatedButton.styleFrom(shape: const CircleBorder(), backgroundColor: stoneColor.withOpacity(0.2)),
          child: const Text(''),
          onPressed: () { _putStone(row, column); },
        ),
      );
    }
    else {
      return FlipCard(
        direction: FlipDirection.HORIZONTAL,
        controller: _stoneFlipControllers[row][column],
        speed: 200,
        front: Container (
          margin: const EdgeInsets.all(2.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(squareSize/2),
            color: stone == Stone.black ? Colors.black : Colors.white,
          ),
        ),
        back: Container (
          margin: const EdgeInsets.all(2.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(squareSize/2),
            color: stone == Stone.black ? Colors.white : Colors.black,
          ),
        ),
      );
    }
  }

  Size _getScreenSize(BuildContext context) {
    final double appBarHeight = AppBar().preferredSize.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height - appBarHeight;
    return Size(screenWidth, screenHeight);
  }

  double _getBoardSize(BuildContext context) {
    final Size screenSize = _getScreenSize(context);
    final double boardSize = screenSize.width < screenSize.height ? screenSize.width  : screenSize.height - 10.0;
    return boardSize;
  }

  Widget _buildTurnCard(BuildContext context) {
    final double cardWidth = _getBoardSize(context) / 2;
    final double cardHeight = cardWidth / 2;
    final double fontSize = cardWidth / 8;

    final Size screenSize = _getScreenSize(context);

    final distance = screenSize.width + cardWidth ;
    final double x = -cardWidth -5 + _turnCardAnimation.value * distance ;
    final double y = screenSize.height / 2 - cardHeight / 2 - 5;

    return Positioned(
      left: x,
      top: y,
      child: Card(
        color: Colors.grey,
        elevation: 10,
        shadowColor: Colors.black,
        child: SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: Center(
            child: Text(
              '● の番です。',
              style: TextStyle(
                fontSize: fontSize,
                color: _gameLogic.turn == Stone.black ? Colors.black : Colors.white,
              )
            )
          ),
        )
      )
    );
  }

  Widget _buildFinishCard(BuildContext context) {
    final Size screenSize = _getScreenSize(context);
    final double cardWidth = screenSize.width * 0.8;
    final double cardHeight = cardWidth * 0.5;
    final double titleSize = cardWidth / 8;
    final double fontSize = titleSize * 0.7;

    final distance = screenSize.height + cardHeight;
    final double x = (screenSize.width - cardWidth) / 2 - 5;
    final double y = -cardHeight -5 + distance * _finishCardAnimation.value;

    int numberOfWhite = _gameLogic.numberOfStone(Stone.white);
    int numberOfBlack = _gameLogic.numberOfStone(Stone.black);
    String result = numberOfWhite != numberOfBlack ? '● のかち' : 'ひきわけ';
    Color resultColor = numberOfWhite > numberOfBlack ? Colors.white : Colors.black;

    return Positioned(
      left: x,
      top: y,
      child: Card(
        color: Colors.grey.withOpacity(0.8),
        elevation: 10,
        shadowColor: Colors.black,
        child: SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: Column(
            children: <Widget> [
              Text(
                result,
                style: TextStyle(
                  fontSize: titleSize,
                  color: resultColor,
                ),
              ),
              Text(
                '●：$numberOfWhite',
                style: TextStyle(
                  fontSize: fontSize,
                  color: Colors.white,
                ),
              ),
              Text(
                '●：$numberOfBlack',
                style: TextStyle(
                  fontSize: fontSize,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        )
      )
    );    
  }

  Widget _buildConfetti(BuildContext context) {
    final double boardSize = _getBoardSize(context);
    final double minSize = boardSize * 0.02;
    final double maxSize = minSize * 2;

    final Size screenSize = _getScreenSize(context);

    return Positioned(
      left: screenSize.width / 2,
      top: -maxSize,
      child: ConfettiWidget(
        confettiController:_confettiController,
        blastDirectionality: BlastDirectionality.directional,
        blastDirection: -pi / 2,
        emissionFrequency: 0.5,
        numberOfParticles: 5,
        shouldLoop: true,
        maxBlastForce: 4,
        minBlastForce: 2,
        displayTarget: false,
        minimumSize: Size(minSize, minSize),
        maximumSize: Size(maxSize, maxSize),
        gravity: 0.0981,
        particleDrag: 0.001,
      ),
    );
  }

  final GameLogicInterface _gameLogic;
  late Animation<double> _turnCardAnimation;
  late AnimationController _turnCardAnimationController;
  late Animation<double> _finishCardAnimation;
  late AnimationController _finishCardAnimationController;
  late ConfettiController _confettiController;
  var _animationPlaying = false;
  late List<List<FlipCardController>> _stoneFlipControllers;
}
