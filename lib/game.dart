import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class MyGame extends FlameGame {
  late Player player;
  late TextComponent scoreText;
  int score = 0;
  final Random random = Random();
  double enemySpawnTimer = 0;
  final double enemySpawnInterval = 2.0;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Add background
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = Colors.blue.shade900,
    ));
    
    // Add player
    player = Player();
    add(player);
    
    // Add score text
    scoreText = TextComponent(
      text: 'Score: $score',
      position: Vector2(20, 50),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(scoreText);
    
    // Add initial enemies
    for (int i = 0; i < 3; i++) {
      addEnemy();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Spawn enemies periodically
    enemySpawnTimer += dt;
    if (enemySpawnTimer >= enemySpawnInterval) {
      addEnemy();
      enemySpawnTimer = 0;
    }
    
    // Simple collision detection
    checkCollisions();
  }

  void addEnemy() {
    final enemy = Enemy();
    enemy.position = Vector2(
      random.nextDouble() * size.x,
      -50,
    );
    add(enemy);
  }

  void increaseScore() {
    score += 10;
    scoreText.text = 'Score: $score';
  }

  void checkCollisions() {
    final enemies = children.whereType<Enemy>().toList();
    for (final enemy in enemies) {
      final distance = player.position.distanceTo(enemy.position);
      if (distance < player.radius + enemy.radius) {
        enemy.removeFromParent();
        increaseScore();
      }
    }
  }
}

class Player extends CircleComponent {
  static const double speed = 100.0;
  double direction = 1;

  Player() : super(radius: 20, paint: Paint()..color = Colors.green);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    position = Vector2(200, 400);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Simple automatic movement left and right
    position.x += direction * speed * dt;
    
    final game = findGame()! as MyGame;
    if (position.x <= radius) {
      direction = 1;
    } else if (position.x >= game.size.x - radius) {
      direction = -1;
    }
  }
}

class Enemy extends CircleComponent {
  static const double speed = 100.0;

  Enemy() : super(radius: 15, paint: Paint()..color = Colors.red);

  @override
  void update(double dt) {
    super.update(dt);
    
    // Move downward
    position.y += speed * dt;
    
    // Remove if off screen
    final game = findGame()! as MyGame;
    if (position.y > game.size.y + 50) {
      removeFromParent();
    }
  }
}
