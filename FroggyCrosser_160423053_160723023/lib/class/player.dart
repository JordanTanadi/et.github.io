class Player {
  String username;
  int score;

  Player({required this.username, required this.score});

  Map<String, dynamic> toJson() {
    return {'username': username, 'score': score};
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      username: json['username'] as String,
      score: json['score'] as int,
    );
  }
}
